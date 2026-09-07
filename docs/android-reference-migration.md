# Android reference migration

Status: **in progress — real account API, protected native sessions and three Android account screens implemented; emulator proof recorded below**.
The cross-repository authority is AssetPipeline's
`docs/ANDROID_COMPILE_TARGET_IMPLEMENTATION_PLAN.md`. Do not equate a generated
counter or a local sign-in form with real AgentC account authentication.

## Preserve the existing web application

The checkout has unrelated in-progress web, authentication, registration and
configuration changes. These are preserved. Its HTML/Tailwind components remain
the web presentation; the native screens will be explicitly authored `UI::View`
trees over shared values/use cases. Grant/PostgreSQL, server sessions, password
hashing, mailers and server secrets must not enter the Android require graph.

Component imports now use logical shard paths (`asset_pipeline/components/...`)
instead of hard-coded relative `lib/asset_pipeline/src/...` paths. This permits
an opt-in dependency projection without mixing installed and current component
implementations. No installed library directory or dependency lock is replaced
by this migration preflight.

## Safe web validation

The ordinary suite now truncates native sessions and regular/admin user tables before every example.
Setting `AMBER_ENV=test` alone is not isolation: `DATABASE_URL`/`DATABASE_URI`
override the configured test database. Never run it against an ambient URL.

Use `scripts/native_reference_spec.cr` with an explicitly task-owned database:

```sh
AGENTC_TEST_DATABASE=agentc_android_your_unique_suffix \
DATABASE_URL=postgres://your_user@127.0.0.1:5432/agentc_android_your_unique_suffix \
crystal run scripts/native_reference_spec.cr
```

Provision and migrate that disposable database separately, after verifying its
exact identity and emptiness. The runner requires the constrained database name
and URL and checks the actual configured writer's `current_database()` before
registering application specs or destructive hooks. It does not provision,
migrate or drop databases. The supplied values above are placeholders, not a
command to run against an existing development or production database.

For read-only boot checks, start the actual built application with explicit
localhost host/port and the isolated database. Then use:

```sh
crystal run scripts/native_reference_web_smoke.cr -- http://127.0.0.1:38247
```

This verifies home/login/signup HTML and signed-out dashboard/settings redirects.
It rejects non-localhost origins. It is not CSRF enforcement or mobile-login proof:
the existing routes omit the CSRF pipe under `AMBER_ENV=test`.

## September 5 evidence

Evidence root: `/tmp/agentc-android-reference.ivvEzN`.
Only the task-owned database `agentc_android_20260905_ivvezn` was created and
migrated. Existing databases are outside the test scope. Both existing migrations
passed. A mismatched expected-database test exited before destructive hooks and
preserved a synthetic sentinel row in the task database.

The installed-dependency baseline passed **307 examples, zero failures/errors,
three pre-existing pending permission checks** after correcting one stale spec:
the existing login form emits `_csrf`, the field both Amber versions actually
read, not `authenticity_token`. No form markup change was needed for that fix.

The actual server build exposed installed Amber's obsolete `Process.fork` path,
which Crystal 1.21 rejects. An opt-in temporary shard projection selects the
current local Amber V2 and AssetPipeline repositories ahead of the existing
project libraries using `CRYSTAL_PATH`. The existing installed dependencies,
`shard.yml`, `shard.lock` and `.amber.yml` remain unchanged by this projection.
The actual application now builds and boots on localhost with these dependencies;
all five read-only route checks pass. The 11 isolated authentication examples pass.

The first complete current-dependency run has **2 failures and 24 errors**:
model adapter resolution reports no database connection after the earlier tests.
A separate direct database/model/health check passes. A complete read-only
health-observation rerun passes **307 examples, zero failures/errors, three
pending**, in 4:20 minutes, without observing a missing writer. No database,
authentication or health-monitor policy was changed to produce that pass. The
first failure's cause remains unconfirmed; do not call it a fixed framework bug.
The final uninstrumented runner also passes **307 examples, zero failures/errors,
three pending**, in 51.44 seconds (`web-current-deps-final.txt`). Retain the unsuccessful evidence
and distinguish it from the passing installed-dependency baseline. Two passing
reruns do not establish the cause of the first run's transient failure.

The actual web server was stopped after its route checks; no temporary listener
is left on port 38247. The task database and evidence remain available for the
next migration step. The physical Android phone is not currently visible to ADB;
the separately verified generated consumer runs on emulator-5556.

The built current-dependency server has SHA-256
`0ed2abb598f72af419817c299bfd0f9505c134b4517a8402ccff5ddc3d97fc7e`.
The final full-suite evidence has SHA-256
`c549af9c2c2fdd36e24d10601e50d6b8056f5dbc47947779f0213c98fcaba934`.

## Next implementation gates

### Completed target-attachment checkpoint

The actual CLI adds 33 Android target/starter files with all 83 existing web,
configuration, dependency and test entries unchanged. The full guarded web/shared
suite passes 309 examples (zero failures/errors, three existing pending checks),
and the rebuilt web server passes its five real localhost route checks.

An isolated, byte-verified projection of this actual attached target passes
79 JVM tests, 13 Android tests, exact-Unicode process restoration and package/
ABI/export/debug-symbol gates on emulator-5556. Its app ID is
`com.example.agentc.app.template.oss`. It retains a counter and name through
restart; **this starter is not AgentC account authentication or the final native
presentation**. The original installed library directories remain untouched.

Evidence: `/tmp/amber-android-target-attachment-proof`. The complete cross-repo
checkpoint is AssetPipeline's `docs/android-target-attachment-proof-2026-09-05.md`.
The new CLI supports `target add android`, `doctor android`, `build android`,
`run android --device SERIAL` and `test android --device SERIAL`, with `--project`
for an explicit directory. Its dry-run/collision rules avoid overwriting existing
source; safe metadata regeneration and custom/Apple-v1 manifest migration remain
explicit follow-up work.

### Next gates

1. Preserve the passing full current-dependency web regression and real server
   boot proof as migration gates. Watch for recurrence of the unconfirmed
   connection-availability failure; do not change production health policy merely
   to hide it in tests.
2. Retain the genuine native account flow replacing the earlier counter starter,
   including its lifecycle, ownership and release/package checks.
   A scoped `build/.gitignore` now excludes `android-*` artifacts without changing
   the existing root ignore file or hiding unrelated web build files.
3. Retain the verified server-only mobile API, shared display-name operation and
   native-safe client described in [the account contract](native-account-api.md).
   Server expiry/revocation, actual account ownership and real HTTPS/web CSRF
   checks pass, and the Android account suite now uses that real TLS API.
4. Keep the protected native session coordinator, Android HTTP/secrets adapters
   and sign-in/account/settings screens within their documented contracts.
   Existing dashboard demo revenue/activity is not real account data and is not
   included in the native presentation.
5. Complete physical-phone and broader API/ABI/device/accessibility proof; keep
   emulator runtime results distinct from full supported/public-release status.

The earlier API checkpoint is AssetPipeline's
`docs/android-agentc-account-api-proof-2026-09-05.md`. The subsequent native-screen
checkpoint is `docs/android-agentc-native-accounts-proof-2026-09-05.md`, with
evidence under `/tmp/agentc-android-accounts.32oJ8d`. It records real native sign-in,
exact Unicode settings, protected different-process restoration and logout on
the isolated ARM64 API 35 emulator. The full Android goal remains active.

## September 6 — commit-pinned dependencies

`shard.yml` no longer carries branch references. Amber pins the native-facade
commit `ab90eae9` on `crimson-knight/amber` and AssetPipeline pins the API 36
migration commit `4c40068c` on `crimson-knight/asset_pipeline`; grant, gemma,
mcprotocol and micrate pin the commits the lock already resolved, and the lock
was rewritten for the two Android-capable shards only. With those installed
into `lib/` (`shards install --without-development --skip-executables`),
`mobile/android/android.sh doctor` passes and `mobile/android/android.sh build`
packages both ABIs, the debug APK and the release bundle with matching native
debug symbols in 52 seconds on the compile/target 36 toolchain. The three-screen
emulator flow against a live account server is recorded in the next section.

## September 6 — live three-screen flow on an API 35 emulator

Evidence root: `~/android_target_evidence/2026-09-06-claude/agentc-live-flow-api35-emulator-5556/`.
Only the task-owned database `agentc_android_20260906_21aec9bc` was created; the
forward migration applied all three migrations (`agentc-migrate.log`) and the
guarded seed created the synthetic reference account (`agentc-seed.log`).
A task-only CA and a `localhost` certificate (SAN `localhost`, `127.0.0.1`,
three-day validity) were generated under the job directory; the public CA is
kept with the evidence, the keys are not. The actual application binary served
`https://127.0.0.1:38248` in `AMBER_ENV=development` with direct TLS and
rejected an unauthenticated account request with 401 before anything else ran.

`scripts/native_reference_account_smoke.cr` passed against that origin
(`agentc-account-smoke.log`): TLS trust, real web CSRF, native sign-in, shared
Unicode edits in both directions, escaping, duplicate headers, pre-body
rejection and logout. `mobile/android/android.sh test emulator-5556` (API 35,
arm64, port mapped with `adb reverse` for the run only and removed afterward)
then passed: every required host unit report, ABI/ELF/symbol checks, and
**OK (13 tests)** on the device, including
`realAccountFlowUsesProtectedSessionAndSharedSettingsAcrossRecreation` with the
sign-in, dashboard, settings, restored-account and relaunch captures under
`screenshots/`. The database confirms the device edit independently: the
reference account's display name is the Unicode value the suite set, and the
native session table is empty after sign-out. The server and the port mapping
were stopped afterward; the task database and evidence remain.

One caveat belongs to the branch, not the flow. Commit 9716cac removed the
`i18n`, `mysql` and `sqlite3` shards while `config/application.cr` and
`config/database.cr` still require them, so the server, the seed script and
the specs do not compile from a clean `shards install` on this branch. This
run projected the main checkout's installed copies of those shards behind the
worktree's own `lib/` through `CRYSTAL_PATH` (`agentc-env.sh` in the evidence)
and changed no tracked file. Either dropping the three requires or restoring
the three shards is a one-commit fix that needs a decision.

## September 7 — release signing from the environment

`mobile/android/app/build.gradle.kts` signs the release APK and App Bundle
when `AMBER_ANDROID_KEYSTORE`, `AMBER_ANDROID_KEYSTORE_PASSWORD`,
`AMBER_ANDROID_KEY_ALIAS` and `AMBER_ANDROID_KEY_PASSWORD` are all set; with
none set the release artifacts stay unsigned as before, and a partial set or a
missing keystore file fails Gradle configuration with the missing names.
`inspect_artifacts.sh` accepts either release APK name, verifies a signed APK
with `apksigner` and the bundle with `jarsigner`, records the signer
certificate or `unsigned` in `release-signing.txt`, and fails when a key was
configured but the output is unsigned. Proven with a throwaway key that lived
only in the task's scratch directory: `android.sh build` produced a signed
`app-release.apk` and `app-release.aab` (inspector PASS), the same build
without the variables produced `app-release-unsigned.apk` with an `unsigned`
record, and one variable alone failed configuration. The upload key and the
Play Console side are outside this repository.

## September 7 — the dropped-shard defect is closed

Commit 9716cac had removed the `i18n` shard while `config/application.cr`
still required `config/i18n.cr`, and `config/database.cr` still required the
`mysql` and `sqlite` Grant adapters behind a comment saying Grant needed every
adapter compiled in. Neither shard was in `shard.yml`, so a clean
`shards install` followed by any host build stopped at `can't find file
'i18n'`. The repair follows the intent of that commit rather than reversing
it:

- `config/database.cr` requires only `grant/adapter/pg`. The comment was true
  of the pinned Grant: `Grant::Transaction#start_transaction` dispatched on
  the adapter constants, which forced all three adapters into every binary.
  Grant commit 4ae3216 ("Fix transaction adapter dispatch to not require all
  adapter constants") switches that dispatch to the adapter's class name, the
  same constant-free pattern the rest of Grant already used. The template now
  pins Grant at the fork head, `56bf23d`, which carries that fix and the
  encryption IV round-trip fix.
- Grant at that commit requires crystal-db 0.14, so `pg` moves from
  `~> 0.28.0` to `~> 0.30.0` (the first crystal-pg release on crystal-db 0.14)
  and the lock resolves `db 0.14.0`, `pg 0.30.0` and the Grant commit above.
- `config/i18n.cr`, its require and `src/locales/en.yml` are gone. Nothing in
  `src/` or `spec/` called `I18n`; the locale file held one unused key.

Proof on this branch: `crystal build --no-codegen` of the web target passes
from the refreshed lock (one pre-existing `Time.monotonic` deprecation
warning). The isolated-database procedure above ran against a task-owned
database that was created empty, migrated forward (three migrations OK) and
dropped afterward: `scripts/native_reference_spec.cr` finished with
350 examples, 0 failures, 0 errors, 3 pending (the three pending examples are
the pre-existing permission placeholders). The Android entry point,
`src/platform/android/app.cr`, never reaches Grant, `pg` or the database
configuration, so the mobile lane's compiled code is unchanged by the pins.
Left alone on purpose: the `Dockerfile` still installs `sqlite-dev` and
`digitalocean-deployment.md` still explains it as a SQLite build need, which
no longer applies; that image is not buildable on this machine, so the
package line stays until a deployment build can prove its removal.

## September 7 — the reference app on a physical phone

`mobile/android/android.sh test` passed on a Samsung Galaxy A15 5G (SM-A156U,
Android 16, One UI 8): 13 tests, the same three-screen account flow against
the task-local TLS account server reached through `adb reverse`, with the
account-proof screenshots pulled from the device. The phone had no network
time (its clock read November 2025), so the task-only certificate authority
and server certificate were reissued with a validity window that covers the
device's date before the run; a phone with a live clock needs no such step.
The evidence lives with the other proof directories outside this repository.
