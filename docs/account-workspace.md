# Shared account workspace — OSS candidate

This is a **local implementation candidate**, not a released feature claim. It
starts from the published OSS `main` at
`3f39e2c8136cd2f4b6aa7a74c4fbd8b91614fb2d`, whose application uses Jennifer 0.13,
single-table `Persona` / `User` authentication, and ECR views. It does not copy
the unpublished Grant/component migration from the canonical worktree.

## What this provides

- `/profile` and `/settings` are authenticated, working account screens.
- A normalized, escaped profile name is persisted on the current account only.
  Email, account ID, STI type, API keys and session identity cannot be changed by
  that form. The full read-only email wraps on narrow screens.
- Password changes verify the current password, confirm the replacement, and
  rotate a server-side session version. Other cookies become invalid, while the
  submitting browser remains signed in. The same protection backs “sign out
  other sessions.” No invented device list is shown.
- Password controls show live rules, a disabled-invalid state, and a pending
  submission state. Ordinary HTML form submission remains usable without JS.
- Sign out is CSRF-protected POST and deletes the actual `user_id` session key.
  The old GET URL shows confirmation without modifying the session.
- The home shows real account details and an honest unconnected-workflow state,
  not sample revenue, customers, activities, projects or team invitations.
- Navigation has only available screens, a functioning mobile menu, Escape
  handling, visible keyboard focus, and a skip link. Workspace CSS is local;
  the existing public landing page retains its Tailwind dependency.

This baseline has **no public account registration or passkey implementation**.
Those controls are not advertised. Premium customer leads, messages, estimates,
calendars and billing are not imported. Existing MCP placeholder capabilities
are not surfaced as functioning owner-dashboard actions by this change.

## Schema and compatibility

Run the existing Jennifer migration mechanism before starting the new binary:

```sh
shards install --frozen --skip-postinstall --skip-executables
crystal build sam.cr -o sam
DATABASE_URL=postgres://... ./sam db:migrate
```

Migration `20260904201100722_add_account_workspace_fields.cr` adds `display_name`
and `session_version` to `personas`; it does not reset customer data. Existing
cookies have no version and must sign in once after deployment. The next
successful sign-in initializes a cryptographically random version. Deployment
must avoid a mixed old/new authentication fleet: an old binary does not check
the version, so it cannot enforce revocation. Down migration removes these two
columns and their data; back up before any rollback, and never roll back to an
old binary as a way to claim session revocation still works.

All direct shard versions/commits are exact pins matching the original lockfile;
no dependency version was upgraded. The checked-in `config/jennifer_compat.cr`
adapts an old Jennifer symbolic validation message to the locked Wordsmith
string API. **No modified dependency tree is required.**

The tested Crystal bcrypt string API counts a trailing NUL within its 72-byte
input buffer. Its real password maximum is therefore **71 UTF-8 bytes**, not 72
characters. UI, controller and model enforce the same 8-character minimum and
71-byte maximum, including multibyte input. This is intentionally explicit until
the cryptography/runtime is upgraded together with a tested migration plan.

The pinned Amber error pipeline converted raised CSRF errors into misleading
404s. `AccountCSRFPipe` retains the exact Amber token validator and directly
returns a non-mutating 403 with refresh guidance. Logs filter credentials,
session cookies, CSRF tokens, and session versions.

## Local verification

The suite refuses any test database except the explicitly named local fixture.
Create it first; no test silently defaults to an application database:

```sh
createdb -h 127.0.0.1 -U "$USER" oss_owner_workspace_test_20260904_01
DATABASE_URL="postgres://$USER@127.0.0.1:5432/oss_owner_workspace_test_20260904_01" \
  AMBER_ENV=test APP_ENV=test crystal spec
```

Tests run the real Amber CSRF/session pipeline and PostgreSQL persistence. They
cover authentication, profile isolation, escaping, invalid-input preservation,
password byte boundaries, current-password verification, session revocation,
safe logout, and absence of fake metrics. Local verified result on September 4:
**18 examples, 0 failures, 0 errors** on stock Crystal 1.21.0; final log retained
outside the repo at `/private/tmp/oss-owner-stock-final-regression-20260904.log`.
JSON sign-in response compatibility is covered alongside ordinary HTML forms.
On this older Amber runtime, builds and tests use `-Dwithout_mt`; the CI job
includes that same flag. The compiler's deprecation warning is not a test
failure.

For a browser rehearsal, create
`oss_owner_workspace_browser_20260904_01`, set `DATABASE_URL` to its loopback
connection, and run `crystal run tooling/seed_account_workspace_fixture.cr`.
This seeds exactly one synthetic account and refuses to reset an existing one.
Start the built application with `AMBER_ENV=test APP_ENV=test HOST=127.0.0.1
PORT=43282`, no email credentials, and that database. Then:

```sh
npm ci --ignore-scripts --prefix tooling/browser
tooling/browser/node_modules/.bin/playwright install chromium
NODE_PATH="$PWD/tooling/browser/node_modules" ACCOUNT_WORKSPACE_FIXTURE=1 \
  node tooling/verify_account_workspace_browser.cjs
```

On macOS the harness defaults to installed Google Chrome; Linux uses the pinned
Playwright Chromium. `ACCOUNT_WORKSPACE_CHROME` can select an explicit browser
binary. Reruns can supply the fixture's current `ACCOUNT_WORKSPACE_PASSWORD` and
a different `ACCOUNT_WORKSPACE_NEW_PASSWORD`; no database reset is necessary.
Browser proof includes 390px/desktop screenshots, a wrapped long email, real
profile writes and reloads, CSRF rejection, live password checks, busy state,
old-session rejection, logout/fresh login, and rendered text contrast. Retained
local proof: `/private/tmp/oss-owner-stock-browser-proof-20260904/result.json`.
These are **local browser proofs**, not physical Safari, native-app, released
behavior, SendGrid delivery or direct inbox inspection. No email is sent.

## CI and release gate

`.github/workflows/account-workspace.yml` adds one read-only, 20-minute-bounded
job for every PR, main push and manual dispatch. Actions, browser packages and
the PostgreSQL fixture image are pinned. It runs the actual database tests,
unsafe-database refusal, app/migration builds and desktop/mobile browser flow.
It has no provider secrets, deployment, mail sends or artifact uploads. The
test result JSON is emitted to the job log.

The baseline had no CI workflow. A checked-in workflow is **not** a green run;
publishing still requires this exact candidate to pass hosted CI before merge.
The old optional Ameba 1.5 postinstall cannot compile on Crystal 1.21; installs
skip postinstall rather than silently changing its version. The owned Crystal
source was linted locally with the existing precompiled Ameba binary; CI runs
the compiler's format check and behavior/security suite, not a claimed Ameba
source build. Full template modernization/Grant migration remains a separate
review, not a prerequisite silently folded into this port.
