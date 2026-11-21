[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/keygen-1?utm_medium=integration&utm_source=button&utm_campaign=keygen)

# Keygen CE on Railway

One-click [Railway](https://railway.com) template for [Keygen CE](https://keygen.sh/docs/self-hosting/), the self-hosted edition of Keygen's software licensing and distribution API.

**Version:** Keygen CE `v1.7.4` (`keygen/api:v1.7.4@sha256:199664efcb35365a5ad479d17ddab80c49b7083ab0561b85b0f96651fc77f558`, the official image on Docker Hub).

## What it deploys

| Service | Source | What it does |
| --- | --- | --- |
| `keygen` | this repo (`Dockerfile`) | Keygen API on a public HTTPS domain. Health check `/v1/health` |
| `keygen-worker` | this repo, start command `/app/railway/start.sh worker` | Sidekiq background jobs |
| `Postgres` | Railway Postgres 18 | Data, on a volume |
| `Redis` | Railway Redis | Queues and cache, on a volume |

The `keygen` service runs `/app/railway/start.sh release` as its pre-deploy command:

- **First deploy:** waits for Postgres, then runs Keygen's `keygen:setup`, which creates the schema, the account (`KEYGEN_ACCOUNT_ID`) and the admin user (`KEYGEN_ADMIN_EMAIL` / `KEYGEN_ADMIN_PASSWORD`). Setup output that would contain secrets is filtered out of the logs.
- **Later deploys:** runs `rails db:migrate` only. Your data is never reset.
- If the database holds a different account than `KEYGEN_ACCOUNT_ID`, it stops with an error instead of running setup again.

The worker waits until setup has created the schema before it starts Sidekiq.

## Variables

| Variable | Service | Default | Notes |
| --- | --- | --- | --- |
| `KEYGEN_ADMIN_EMAIL` | keygen | `admin@example.com` | Admin login. Change it before the first deploy: setup runs once |
| `KEYGEN_ADMIN_PASSWORD` | keygen | generated (24 chars) | Admin password. Read it from the service's Variables tab |
| `KEYGEN_ACCOUNT_ID` | keygen | generated UUID | Your account ID, part of every API path |
| `KEYGEN_HOST` | keygen | `${{RAILWAY_PUBLIC_DOMAIN}}` | Public hostname. Change it when you add a custom domain |
| `SECRET_KEY_BASE`, `ENCRYPTION_*` | keygen | generated | Keep them: they protect data at rest |
| `DATABASE_URL`, `REDIS_URL` | both | references to Postgres and Redis | |

Fixed settings live in `railway/start.sh` (`BIND=::`, `KEYGEN_EDITION=CE`, `KEYGEN_MODE=singleplayer`, `RAILS_MAX_THREADS=5`). `KEYGEN_HOSTS` always allows Railway's health checker. Keygen only answers API routes on `KEYGEN_HOST` over HTTPS, so other services should call the public URL (`${{keygen.KEYGEN_URL}}`).

## First request

```bash
# Get an admin token
curl -s -X POST "https://$KEYGEN_HOST/v1/accounts/$KEYGEN_ACCOUNT_ID/tokens" \
  -u "$KEYGEN_ADMIN_EMAIL:$KEYGEN_ADMIN_PASSWORD" -H 'Accept: application/vnd.api+json'

# Validate a license key (no auth needed)
curl -s -X POST "https://$KEYGEN_HOST/v1/accounts/$KEYGEN_ACCOUNT_ID/licenses/actions/validate-key" \
  -H 'Content-Type: application/vnd.api+json' -d '{"meta":{"key":"YOUR-LICENSE-KEY"}}'
```

Keygen CE is API-only; see the [API reference](https://keygen.sh/docs/api/).

## Updates

Both Keygen services build from this repo's `main` branch. When the pinned Keygen version changes here, Railway shows an "update available" notice on projects deployed from the template, and you choose when to apply it. Read [CHANGELOG.md](CHANGELOG.md) first. Migrations run automatically in the pre-deploy step.

## License

The wrapper files in this repo are MIT. Keygen itself is published under the [Fair Core License](https://keygen.sh/license/) (source-available): you may self-host it for your own products, but not offer it as a competing licensing service. This is a community-maintained package and does not imply affiliation with or endorsement by Keygen LLC.
