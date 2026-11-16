# Prints the Keygen database state without booting Rails
# (Rails can't boot in singleplayer mode until the accounts table exists):
#   down  - Postgres not reachable yet
#   empty - no Keygen schema yet (first boot)
#   fresh - schema exists but no account (an earlier setup stopped half-way)
#   ready - the account KEYGEN_ACCOUNT_ID exists
#   other - accounts exist, but not KEYGEN_ACCOUNT_ID
require "pg"

begin
  conn = PG.connect(ENV.fetch("DATABASE_URL"), connect_timeout: 5)
rescue PG::Error => e
  warn "postgres: #{e.message.lines.first.to_s.strip}"
  puts "down"
  exit 0
end

if conn.exec("SELECT to_regclass('public.accounts') IS NULL").getvalue(0, 0) == "t"
  puts "empty"
elsif conn.exec("SELECT count(*) FROM accounts").getvalue(0, 0).to_i.zero?
  puts "fresh"
elsif conn.exec_params("SELECT 1 FROM accounts WHERE id::text = $1", [ENV.fetch("KEYGEN_ACCOUNT_ID", "")]).ntuples.positive?
  puts "ready"
else
  puts "other"
end
