# Android application

This is a native Android View application, not a WebView wrapper. Its Crystal
entrypoint is `src/platform/android/app.cr`; shared rules live in `src/app`.
The Activity and project belong to this app. JNI/runtime/listener implementations
come from the installed AssetPipeline shard, not from a showcase checkout.

From the project root, after installing Android-capable Amber and AssetPipeline:

```sh
bash mobile/android/android.sh doctor
AGENTC_ANDROID_API_ORIGIN=https://your-account-server.example \
bash mobile/android/android.sh build
AGENTC_ANDROID_API_ORIGIN=https://your-account-server.example \
bash mobile/android/android.sh run emulator-5554
```

The first build compiles GC/PCRE2 dependencies for all selected ABIs. Set
`CRYSTAL_CROSS_DEPS` to share a verified cache. SDK/NDK/JDK resolution uses
AssetPipeline's pinned contract. No `local.properties` with a developer SDK path
is generated. The Gradle distribution and embedded wrapper have verified hashes.

`config/native.yml` is the source for generated app properties, manifest,
configuration and resources. Regenerate deliberately when changing it; preserve
handwritten screen/domain code. Custom icon/color resource references must exist
before building. Verified links still need website association and runtime tests.

`config/android_assets.yml` maps logical `UI::Image` names to project-local PNG,
JPEG, WebP or Android VectorDrawable XML files. Gradle compiles this catalog into
native resources on every build. Sign-in uses its bundled `app_mark`; no
network request or WebView is involved. Optional `dark_source` selects an Android
night-mode variant and `density` defaults to `nodpi`. SVG needs an explicit
Android export. See AssetPipeline's `docs/android-images.md` for bounds and
unsupported formats. Edit catalog/source files, never generated build resources.

The real account flow has three native screens: sign-in, an account dashboard,
and account settings. Display-name validation and the server operation are shared
with the web application. It does not present the web dashboard's sample revenue
or activity as real account data. Existing web/ORM/server entrypoints are excluded
from the Android build.

For HTTP APIs, explicitly enable the network capability in the manifest and use
`require "amber/native/android_http"` with `Amber::Native::Android::HTTPClient`.
The shared Android host uses platform TLS/trust, bounded binary payloads, explicit
redirects and cancellable worker requests. It does not include Crystal OpenSSL.
See the Amber shard's `docs/android-http.md` for limits and error semantics.
`AGENTC_ANDROID_API_ORIGIN` is compile-time configuration, not a secret. It must
be a bare HTTPS origin, with an optional port. The default reserved `.invalid`
origin displays setup instructions and disables sign-in; it never guesses a
production service. Configure the actual server's direct TLS listener as described
in `docs/native-account-api.md`.
Both hosts use AssetPipeline's pinned `android/runtime/dependencies.gradle.kts`.

Session credentials are stored through the Keystore-backed Secrets adapter,
bound to that exact origin. Passwords, profile data, drafts and navigation history
are not persisted. Password drafts are cleared on submit and background. A fresh
process reads protected credentials and fetches the current account from the API.
Sign-out waits for pending writes and confirmed protected deletion; failed
deletion is visibly incomplete and must be retried. Network revocation failure is
reported separately from completed local deletion. A process killed before the
delete acknowledgment has interrupted sign-out, not completed durable logout.

Tests launch this Activity and verify native state, validation and recreation.
Missing devices and crashed/empty instrumentation are failures, never passes.
Host-session, service-queue, HTTP wire and HTTP worker test reports are required;
missing, empty or failed reports stop the proof before device instrumentation.
The test edits the seeded synthetic account without clearing application data;
use a dedicated development app ID, not an app containing important user data.
It then starts a new process, restores the protected session and reloads the exact
Unicode account name, signs out and verifies another launch stays signed out.
It preserves draft/focus/selection across Activity recreation, not process death.
Only one mounted native root per process is supported. Service capability
declarations do not grant runtime permissions. Other platform adapters remain open.

Account instrumentation intentionally requires a **task-local HTTPS server**,
the guarded synthetic seed and an explicit public task CA. Follow the isolated
database/server instructions in `docs/native-account-api.md` first. With the
chosen localhost port reachable from the explicitly selected emulator:

```sh
AGENTC_ANDROID_API_ORIGIN=https://localhost:38248 \
AGENTC_ANDROID_TEST_CA=/absolute/path/to/task-only-ca.crt \
bash mobile/android/android.sh test emulator-5556
```

If using USB/ADB forwarding, add only the chosen port's reverse mapping and
remove only that mapping afterward; never clear someone else's mappings. The
driver does not provision a database, trust a CA globally, change the server,
seed or clear data, or select a device automatically. Missing server/CA/device,
failed/empty tests, crashes and missing evidence are failures. The public CA is
generated into debug-only resources; release never adopts local test trust.
The synthetic password belongs to the separate instrumentation APK and is checked
absent from the main debug APK, release APK and App Bundle.

Release-mode bundles retain native debug symbols. Supply release signing outside
source control and complete the runtime/device/store-policy checks before release.
The wider Android target is still in development; released-dependency consumer
proof remains required before this generator can be advertised as supported.
