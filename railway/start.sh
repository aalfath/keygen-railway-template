#!/usr/bin/env bash
# Railway wrapper for Keygen CE.
#   start.sh release  -> pre-deploy: wait for Postgres, first-boot setup or migrations
#   start.sh web      -> API server (listens on $PORT)
#   start.sh worker   -> Sidekiq worker (waits until setup has created the schema)
# Anything else is passed to Keygen's own entrypoint.
set -euo pipefail

# Railway may run the pre-deploy/start command through this entrypoint too
# ("start.sh /app/railway/start.sh release"), so unwrap that.
if [ "${1:-}" = "/app/railway/start.sh" ] || [ "${1:-}" = "$0" ]; then shift; fi

cd /app

# Defaults that don't need to be template variables.
export BIND="::"                                 # IPv6 + IPv4 (the image defaults to 0.0.0.0, IPv4 only)
export PORT="${PORT:-3000}"
export RAILS_MAX_THREADS="${RAILS_MAX_THREADS:-5}"
export RAILS_LOG_TO_STDOUT="${RAILS_LOG_TO_STDOUT:-1}"
export KEYGEN_EDITION="${KEYGEN_EDITION:-CE}"
export KEYGEN_MODE="${KEYGEN_MODE:-singleplayer}"
# Rails host authorization: Railway's health checker calls with its own Host header.
export KEYGEN_HOSTS="${KEYGEN_HOSTS:+$KEYGEN_HOSTS,}healthcheck.railway.app"

# Database state without booting Rails: down | empty | fresh | ready | other (see db_state.rb).
db_state() {
  local out
  if ! out="$(bundle exec ruby /app/railway/db_state.rb)"; then
    echo "db_state.rb failed" >&2; echo error; return 0
  fi
  echo "$out"
}

wait_for_db() {
  local state
  for _ in $(seq 1 60); do
    state="$(db_state)"
    case "$state" in
      down) ;;
      error) return 1 ;;
      *) echo "$state"; return 0 ;;
    esac
    echo "waiting for Postgres..." >&2
    sleep 5
  done
  echo "Postgres is not reachable after 5 minutes (check DATABASE_URL)" >&2
  return 1
}

case "${1:-web}" in
release)
  state="$(wait_for_db)"
  case "$state" in
    ready)
      echo "Keygen account found, running migrations"
      exec bundle exec rails db:migrate
      ;;
    empty|fresh)
      : "${KEYGEN_ACCOUNT_ID:?KEYGEN_ACCOUNT_ID is required}"
      : "${KEYGEN_ADMIN_EMAIL:?KEYGEN_ADMIN_EMAIL is required}"
      : "${KEYGEN_ADMIN_PASSWORD:?KEYGEN_ADMIN_PASSWORD is required}"
      echo "First boot: running keygen:setup (creates the schema, the account and the admin user)"
      # "fresh" = schema exists but no account (an earlier setup stopped half-way): safe to reload.
      [ "$state" = fresh ] && export DISABLE_DATABASE_ENVIRONMENT_CHECK=1
      # Setup prints the secrets it was given; keep them out of the logs.
      bundle exec rails keygen:setup </dev/null 2>&1 | grep -vE '(KEY|SECRET|SALT|PASSWORD)[A-Z_]*='
      ;;
    other)
      echo "The database already holds a Keygen account, but not KEYGEN_ACCOUNT_ID." >&2
      echo "Refusing to run setup (it would erase the data). Set KEYGEN_ACCOUNT_ID to the existing account's ID." >&2
      exit 1
      ;;
  esac
  ;;
web)
  exec /app/scripts/entrypoint.sh web
  ;;
worker)
  # On a first deploy the worker can start before setup has created the schema.
  for _ in $(seq 1 120); do
    case "$(db_state)" in ready|other|error) break ;; esac
    echo "waiting for Keygen setup to finish..." >&2
    sleep 5
  done
  exec /app/scripts/entrypoint.sh worker
  ;;
*)
  exec /app/scripts/entrypoint.sh "$@"
  ;;
esac
