# AgentC App Template (OSS)

A batteries-included **Crystal + [Amber](https://amberframework.org)** web app
template. Authentication, sessions, email, file storage, a typed component view
system, and database migrations are already wired up — so you can start building
your idea instead of your plumbing.

This is the open-source foundation from [AgentC](https://agentc.consulting).
It runs on **stock Crystal and stock Shards** — no special toolchain required.
MIT licensed: fork it, ship it, sell it.

---

## Quick start (5 steps)

For macOS or Linux users comfortable with a terminal.

```bash
# 1. Create your repo from this template, then clone & enter it
gh repo create my-app --template AgentC-Consulting/agentc-app-template --public --clone
cd my-app

# 2. Install Crystal + PostgreSQL (skip any you already have)
#    macOS:  brew install crystal postgresql@17 && brew services start postgresql@17
#    Linux:  see https://crystal-lang.org/install/  +  apt install postgresql

# 3. One-command setup: deps, .env, databases, migrations, seeds
bin/setup

# 4. Start the app
bin/server            # → http://localhost:3000

# 5. (optional) Make it yours — rename the app in one command
bin/new-app my_app
```

That's it. `bin/setup` is idempotent — re-run it any time.

---

## What's included

| Area | What you get |
|---|---|
| **Auth** | Email + password (BCrypt), sessions, login/logout, `Users::Regular` + `Users::Admin` types |
| **Email** | [Quartz Mailer](https://github.com/amberframework/quartz-mailer): welcome, password-reset, verification templates (component-based) |
| **Database** | [Grant ORM](https://github.com/crimson-knight/grant) (Active Record-style) on PostgreSQL, `.sql` migrations via [micrate](https://github.com/amberframework/micrate) |
| **File storage** | [Gemma](https://github.com/crimson-knight/gemma): local in dev, S3/DigitalOcean Spaces in prod |
| **Views** | Type-safe, cacheable component system ([asset_pipeline](https://github.com/amberframework/asset_pipeline)) — not string templates |
| **AI-ready** | [MCProtocol](https://github.com/crimson-knight/mcprotocol) client + an MCP tools registry |
| **Tests** | `crystal spec` suite covering controllers, components, and auth |

> Looking for MFA, OAuth SSO, organizations/teams, RBAC, audit logging, and
> SOC 2 / ISO 27001 compliance scaffolding? Those live in the **premium**
> template, which builds on this core.

## Daily commands

```bash
bin/server                 # run the app (loads .env)
crystal spec               # run the test suite
bin/micrate up             # apply new migrations  (bin/setup builds bin/micrate)
bin/micrate status         # see migration state
crystal tool format        # format code
bin/ameba                  # lint (after: crystal build bin/ameba.cr -o bin/ameba)
```

## Project layout

```
src/
  controllers/   # HTTP handlers (public/ + authenticated/)
  models/        # Grant models (users/)
  views/         # typed view components (not ERB)
  mailers/       # email
config/          # database.cr (ENV-based), routes.cr, application.cr
db/
  migrations/    # .sql migrations (micrate)
  micrate.cr     # migration runner (ENV-based; no YAML/ERB)
bin/             # setup, server, new-app helpers
spec/            # tests
help/            # how-to guides for building each part
```

## Configuration

Configuration is environment-based (12-factor). `bin/setup` creates `.env` from
[`.env.example`](.env.example). Local development needs nothing beyond a running
PostgreSQL — the app connects as your shell user (`whoami`) to
`<app>_development` by default. Override with `DATABASE_URL` or the `DB_*` vars
in `.env`. Never commit `.env` or `.encryption_key` (both are git-ignored).

## Deploy

A production `Dockerfile` and `migrate.sh` are included. See the in-repo
deployment notes, or use AgentC's hardened DigitalOcean runbook (premium).

## License

MIT © AgentC Consulting. See [LICENSE](LICENSE).
