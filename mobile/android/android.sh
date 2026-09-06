#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
asset_root="$project_root/lib/asset_pipeline"
[[ -f "$asset_root/scripts/android_env.sh" ]] || { echo "Install the Android-capable AssetPipeline shard first." >&2; exit 1; }
source "$asset_root/scripts/android_env.sh"
android_resolve_sdk_root
android_resolve_java_home
export ANDROID_SDK_ROOT="$ANDROID_RESOLVED_SDK_ROOT"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export JAVA_HOME="$ANDROID_RESOLVED_JAVA_HOME"
adb="$ANDROID_SDK_ROOT/platform-tools/adb"
action="${1:-build}"
serial="${2:-}"
setting() { awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$script_dir/android-app.properties"; }
app_id="$(setting applicationId)"
gradle_args=(--console=plain)
if [[ -n "${AGENTC_ANDROID_TEST_CA:-}" ]]; then
  [[ -f "$AGENTC_ANDROID_TEST_CA" ]] || { echo "Missing public account test CA certificate" >&2; exit 2; }
  gradle_args+=("-PagentcTestCa=$AGENTC_ANDROID_TEST_CA")
fi
cd "$script_dir"
case "$action" in
  doctor) exec bash "$asset_root/scripts/doctor_android.sh" ;;
  build)
    ./gradlew :app:assembleDebug :app:assembleRelease :app:bundleRelease "${gradle_args[@]}"
    exec bash "$script_dir/inspect_artifacts.sh"
    ;;
  run|test) ;;
  *) echo "Usage: $0 doctor|build|run|test [adb-serial]" >&2; exit 2 ;;
esac
[[ -n "$serial" ]] || { echo "Specify an ADB serial. No device test has been run." >&2; exit 2; }
[[ "$("$adb" -s "$serial" get-state)" == device ]] || { echo "ADB target is not ready: $serial" >&2; exit 1; }
[[ "$("$adb" -s "$serial" shell getprop sys.boot_completed | tr -d '\r')" == 1 ]] || { echo "Android has not completed boot: $serial" >&2; exit 1; }
if [[ "$action" == test ]]; then
  # This suite edits only the documented synthetic account on a task-local
  # HTTPS server. It must never silently point at a production account service.
  [[ "${AGENTC_ANDROID_API_ORIGIN:-}" =~ ^https://localhost:[0-9]{1,5}$ && -n "${AGENTC_ANDROID_TEST_CA:-}" ]] || {
    echo "Account tests require an explicit localhost HTTPS proof origin and AGENTC_ANDROID_TEST_CA. See docs/native-account-api.md." >&2; exit 2;
  }
  status="$(curl --silent --show-error --cacert "$AGENTC_ANDROID_TEST_CA" --max-time 10 --output /dev/null --write-out '%{http_code}' "$AGENTC_ANDROID_API_ORIGIN/api/native/v1/account")"
  [[ "$status" == 401 ]] || { echo "The task-local account API did not reject an unauthenticated request as expected." >&2; exit 1; }
fi
./gradlew :app:testDebugUnitTest :app:assembleDebug :app:assembleDebugAndroidTest :app:assembleRelease :app:bundleRelease "${gradle_args[@]}"
"$adb" -s "$serial" install -r app/build/outputs/apk/debug/app-debug.apk
if [[ "$action" == run ]]; then
  exec "$adb" -s "$serial" shell am start -S -W -n "$app_id/dev.amber.generated.MainActivity"
fi
"$adb" -s "$serial" install -r app/build/outputs/apk/androidTest/debug/app-debug-androidTest.apk
previous_checkjni="$("$adb" -s "$serial" shell getprop debug.checkjni | tr -d '\r')"
restore_checkjni() { "$adb" -s "$serial" shell setprop debug.checkjni "${previous_checkjni:-0}" > /dev/null 2>&1 || true; }
trap restore_checkjni EXIT
"$adb" -s "$serial" shell setprop debug.checkjni 1
[[ "$("$adb" -s "$serial" shell getprop debug.checkjni | tr -d '\r')" == 1 ]]
evidence="${ANDROID_TEST_EVIDENCE:-$project_root/build/android-test-evidence}"
mkdir -p "$evidence"
host_test_report="app/build/test-results/testDebugUnitTest/TEST-dev.assetpipeline.androidhost.HostSessionTest.xml"
[[ -s "$host_test_report" ]] || { echo "Missing canonical host-session unit test report" >&2; exit 1; }
grep -Eq '<testsuite .*tests="[1-9][0-9]*".*failures="0".*errors="0"' "$host_test_report" || {
  echo "Host-session unit tests were empty or failed" >&2; exit 1;
}
cp "$host_test_report" "$evidence/host-session-unit-tests.xml"
service_test_report="app/build/test-results/testDebugUnitTest/TEST-dev.assetpipeline.androidhost.ServiceQueueTest.xml"
[[ -s "$service_test_report" ]] || { echo "Missing canonical service-queue unit test report" >&2; exit 1; }
grep -Eq '<testsuite .*tests="[1-9][0-9]*".*failures="0".*errors="0"' "$service_test_report" || {
  echo "Service-queue unit tests were empty or failed" >&2; exit 1;
}
cp "$service_test_report" "$evidence/service-queue-unit-tests.xml"
for suite in HttpWireTest PlatformHttpTest SecretVaultTest FilePolicyTest NotificationWireTest PermissionRequestsTest EditorActionsTest LayoutPolicyTest ViewStatePolicyTest SemanticsPolicyTest CompoundFocusPolicyTest DialogPolicyTest SheetPolicyTest; do
  report="app/build/test-results/testDebugUnitTest/TEST-dev.assetpipeline.androidhost.$suite.xml"
  [[ -s "$report" ]] || { echo "Missing canonical service unit test report: $suite" >&2; exit 1; }
  grep -Eq '<testsuite .*tests="[1-9][0-9]*".*failures="0".*errors="0"' "$report" || {
    echo "Service unit tests were empty or failed: $suite" >&2; exit 1;
  }
  cp "$report" "$evidence/$suite.xml"
done
log_start="$("$adb" -s "$serial" shell "date '+%m-%d %H:%M:%S.000'" | tr -d '\r')"
"$adb" -s "$serial" shell am instrument -w -r -e class dev.amber.generated.AccountApplicationTest,dev.assetpipeline.androidhost.StoragePlatformTest,dev.assetpipeline.androidhost.SecretsPlatformTest,dev.assetpipeline.androidhost.FilesPlatformTest \
  "$app_id.test/androidx.test.runner.AndroidJUnitRunner" > "$evidence/instrumentation.txt" 2>&1
if ! grep -Eq '^OK \([1-9][0-9]* tests?\)' "$evidence/instrumentation.txt" ||
    ! grep -q '^INSTRUMENTATION_CODE: -1' "$evidence/instrumentation.txt" ||
    grep -Eq 'Process crashed|FAILURES!!!|INSTRUMENTATION_FAILED|INSTRUMENTATION_STATUS_CODE: -[1234]' "$evidence/instrumentation.txt"; then
  echo "Android instrumentation failed; inspect $evidence" >&2; exit 1
fi
"$adb" -s "$serial" logcat -d -v threadtime -T "$log_start" > "$evidence/logcat.txt"
grep -q 'Crystal runtime ready (probe=42)' "$evidence/logcat.txt"
grep -q 'Late-enabling -Xcheck:jni' "$evidence/logcat.txt"
awk '/AssetPipelineNative: JNI_OnLoad: starting/ { pids[$3] = 1 }
  { lines[NR] = $0; owners[NR] = $3 }
  END { for (i = 1; i <= NR; i++) if (owners[i] in pids) print lines[i] }' \
  "$evidence/logcat.txt" > "$evidence/app-logcat.txt"
if grep -Eq 'JNI DETECTED ERROR|FATAL EXCEPTION|Fatal signal|Crystal (bootstrap|render|application) error|Crystal .*callback failed|Cannot enter Crystal' "$evidence/app-logcat.txt"; then
  echo "Android runtime failure; inspect $evidence" >&2; exit 1
fi
previous_pid="$(sed -n 's/^INSTRUMENTATION_STATUS: account_persisted_process=//p' "$evidence/instrumentation.txt" | tr -d '\r')"
[[ "$previous_pid" =~ ^[0-9]+$ ]]
# XML dumps may sanitize supplementary characters. Verify exact Unicode via
# native accessibility strings in a distinct, read-only instrumentation process.
"$adb" -s "$serial" shell am instrument -w -r -e class dev.amber.generated.AccountRestorationTest \
  -e previous_pid "$previous_pid" \
  "$app_id.test/androidx.test.runner.AndroidJUnitRunner" > "$evidence/restoration-instrumentation.txt" 2>&1
if ! grep -Eq '^OK \([1-9][0-9]* tests?\)' "$evidence/restoration-instrumentation.txt" ||
    ! grep -q '^INSTRUMENTATION_CODE: -1' "$evidence/restoration-instrumentation.txt" ||
    grep -Eq 'Process crashed|FAILURES!!!|INSTRUMENTATION_FAILED|INSTRUMENTATION_STATUS_CODE: -[1234]' "$evidence/restoration-instrumentation.txt"; then
  echo "Android exact-state restoration failed; inspect $evidence" >&2; exit 1
fi
restored_pid="$(sed -n 's/^INSTRUMENTATION_STATUS: account_restored_process=//p' "$evidence/restoration-instrumentation.txt" | tr -d '\r')"
[[ "$restored_pid" =~ ^[0-9]+$ && "$restored_pid" != "$previous_pid" ]]
"$adb" -s "$serial" logcat -d -v threadtime -T "$log_start" --pid="$restored_pid" > "$evidence/restoration-logcat.txt"
grep -q 'Crystal runtime ready (probe=42)' "$evidence/restoration-logcat.txt"
if grep -Eq 'JNI DETECTED ERROR|FATAL EXCEPTION|Fatal signal|Crystal (bootstrap|render|application) error|Crystal .*callback failed|Cannot enter Crystal' "$evidence/restoration-logcat.txt"; then
  echo "Restoration process failed; inspect $evidence" >&2; exit 1
fi
"$adb" -s "$serial" shell am start -S -W -n "$app_id/dev.amber.generated.MainActivity" > "$evidence/relaunch.txt"
"$adb" -s "$serial" shell uiautomator dump /sdcard/amber-generated-proof.xml > /dev/null
"$adb" -s "$serial" pull /sdcard/amber-generated-proof.xml "$evidence/relaunch-ui.xml" > /dev/null
grep -q 'Welcome to AgentC' "$evidence/relaunch-ui.xml"
if grep -Eq 'Your account|Account settings|native-emulator@example.test' "$evidence/relaunch-ui.xml"; then
  echo "Signed-out account data reappeared after a new process launch" >&2; exit 1
fi
"$adb" -s "$serial" exec-out screencap -p > "$evidence/relaunch.png"
"$adb" -s "$serial" shell pidof "$app_id" > "$evidence/relaunch-pid.txt"
relaunch_pid="$(tr -d '\r\n' < "$evidence/relaunch-pid.txt")"
[[ "$relaunch_pid" =~ ^[0-9]+$ ]]
[[ "$relaunch_pid" != "$previous_pid" ]] || { echo "Persistence test did not start a new process" >&2; exit 1; }
"$adb" -s "$serial" logcat -d -v threadtime -T "$log_start" --pid="$relaunch_pid" > "$evidence/relaunch-logcat.txt"
grep -q 'Crystal runtime ready (probe=42)' "$evidence/relaunch-logcat.txt"
if grep -Eq 'JNI DETECTED ERROR|FATAL EXCEPTION|Fatal signal|Crystal (bootstrap|render|application) error|Crystal .*callback failed|Cannot enter Crystal' "$evidence/relaunch-logcat.txt"; then
  echo "Relaunched Android process failed; inspect $evidence" >&2; exit 1
fi
if grep -Eq 'Android-reference-only-2026!|wrong-reference-password|Bearer [A-Za-z0-9_-]{43}' \
    "$evidence/app-logcat.txt" "$evidence/restoration-logcat.txt" "$evidence/relaunch-logcat.txt"; then
  echo "Account credentials appeared in scoped runtime/test logs; inspect private proof files" >&2; exit 1
fi
bash "$script_dir/inspect_artifacts.sh" "$evidence/artifacts"
mkdir -p "$evidence/screenshots"
for screen in signin signin-dark signin-light settings dashboard restored-account; do
  "$adb" -s "$serial" pull "/sdcard/Android/data/$app_id/files/account-proof/$screen.png" "$evidence/screenshots/$screen.png" > /dev/null
  [[ -s "$evidence/screenshots/$screen.png" ]]
done
echo "Android application tests passed. Evidence: $evidence"
