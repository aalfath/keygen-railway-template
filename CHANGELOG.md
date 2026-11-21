# Changelog

## 2026-11-21: Keygen CE v1.7.4

- No breaking changes. Accounts, products, policies and licenses in Postgres are kept.
- Fix for an upstream packaging bug: the `keygen/api:v1.7.4` image ships its start scripts with Windows (CRLF) line endings, so on its own it can't start (`env: can't execute 'bash\r'`). The Dockerfile strips the CRs from `/app/scripts/entrypoint.sh` and `/app/bin/*` at build time; on images without the bug this does nothing. The `release` step runs one new migration (a renewal strategy column on policies) before the web and worker start.
- Keygen CE [v1.7.4](https://github.com/keygen-sh/keygen-api/compare/v1.7.3...v1.7.4): Rails and Ruby upgrades, rate limits on webhook endpoint changes, a timeout on DNS lookups in URL validation, read-only users can manage their own MFA, renewal strategies on policies, and dynamic filters on webhook events.
- Image: `keygen/api:v1.7.4@sha256:199664efcb35365a5ad479d17ddab80c49b7083ab0561b85b0f96651fc77f558`.

## 2026-11-16: Keygen CE v1.7.3, built from this repo

- **Breaking for nobody:** projects deployed earlier from the `keygen-1` template ran the image `keygen/api:v1.7.2` directly and don't follow this repo. New deploys build from here.
- Keygen CE `v1.7.2` → `v1.7.3` (`keygen/api:v1.7.3@sha256:4a5550da52bb2ee9b37ba245ddfe5c3809e062efe802c5354510dfe4217e0102`): Rails and Ruby upgrades, search and password-reset fixes ([upstream compare](https://github.com/keygen-sh/keygen-api/compare/v1.7.2...v1.7.3)).
- New `railway/start.sh` wrapper with `release`, `web` and `worker` modes.
- Fixed the first-deploy wait: the old pre-deploy check booted Rails to test the database, which always fails before the schema exists, so every first deploy spent about 5 minutes in 40 retries before setup ran. The check now talks to Postgres directly (`railway/db_state.rb`).
- Setup no longer runs again when the database holds a different account than `KEYGEN_ACCOUNT_ID` (it would have reset the database); the pre-deploy step stops with an error instead.
- The worker waits for setup to finish before starting Sidekiq.
- `BIND=::` is now forced (the image default `0.0.0.0` is IPv4 only).
- Fixed settings (`BIND`, `KEYGEN_EDITION`, `KEYGEN_MODE`, `KEYGEN_HOSTS`, `RAILS_MAX_THREADS`, `RAILS_LOG_TO_STDOUT`) moved from template variables into `railway/start.sh`.
