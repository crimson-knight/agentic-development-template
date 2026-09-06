#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
source "$project_root/lib/asset_pipeline/scripts/android_env.sh"
android_resolve_ndk_host_tag
evidence="${1:-$project_root/build/android-artifact-evidence}"
mkdir -p "$evidence"
setting() { awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$script_dir/android-app.properties"; }
apk="$script_dir/app/build/outputs/apk/debug/app-debug.apk"
release_apk="$script_dir/app/build/outputs/apk/release/app-release-unsigned.apk"
bundle="$script_dir/app/build/outputs/bundle/release/app-release.aab"
unzip -Z1 "$apk" > "$evidence/apk-entries.txt"
unzip -Z1 "$bundle" > "$evidence/bundle-entries.txt"
unzip -Z1 "$release_apk" > "$evidence/release-apk-entries.txt"
grep -Fxq 'base/res/xml/ap_image_catalog.xml' "$evidence/bundle-entries.txt"
cp "$script_dir/app/build/generated/assetPipelineImages/manifest.json" "$evidence/image-source-manifest.json"
aapt2="$ANDROID_RESOLVED_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_VERSION/aapt2"
image_catalog="$script_dir/app/build/generated/assetPipelineImages/res/xml/ap_image_catalog.xml"
[[ -s "$image_catalog" && -r "$image_catalog" ]] || { echo "Missing generated image catalog" >&2; exit 1; }
expected_internet="$(setting internetPermission)"
[[ "$expected_internet" == true || "$expected_internet" == false ]]
expected_notifications="$(setting notificationPermission)"
[[ "$expected_notifications" == true || "$expected_notifications" == false ]]
for variant in debug release; do
  packaged="$apk"
  entries="$evidence/apk-entries.txt"
  [[ "$variant" != release ]] || packaged="$release_apk"
  [[ "$variant" != release ]] || entries="$evidence/release-apk-entries.txt"
  "$aapt2" dump xmltree "$packaged" --file AndroidManifest.xml > "$evidence/$variant-manifest.txt"
  grep -Eq ':enableOnBackInvokedCallback\([^)]*\)=true' "$evidence/$variant-manifest.txt" || {
    echo "Packaged $variant application did not opt in to Android predictive Back" >&2; exit 1;
  }
  # Release resource paths may be shortened (e.g. res/l2.xml). Resolve every
  # generated drawable and catalog through the resource table, then prove its
  # payload actually exists in this APK. Do not assume debug filenames.
  "$aapt2" dump resources "$packaged" > "$evidence/$variant-resources.txt"
  while IFS= read -r resource; do
    payloads="$(awk -v wanted="$resource" '$1 == "resource" { selected = ($3 == wanted) }
      selected && match($0, /\(file\) [^ ]+/) { value = substr($0, RSTART + 7, RLENGTH - 7); print value }' "$evidence/$variant-resources.txt")"
    [[ -n "$payloads" ]] || { echo "Packaged $variant image resource is missing: $resource" >&2; exit 1; }
    while IFS= read -r payload; do
      grep -Fxq "$payload" "$entries" || { echo "Packaged $variant image payload is missing: $payload" >&2; exit 1; }
    done <<< "$payloads"
  done < <(echo xml/ap_image_catalog; { grep -Eo '@drawable/ap_image_[0-9a-f]{32}' "$image_catalog" || true; } | sed 's/^@//' | LC_ALL=C sort -u)
  "$aapt2" dump permissions "$packaged" > "$evidence/$variant-permissions.txt"
  actual_internet=false
  if grep -Eq "^uses-permission: name='android.permission.INTERNET'" "$evidence/$variant-permissions.txt"; then actual_internet=true; fi
  [[ "$actual_internet" == "$expected_internet" ]] || {
    echo "Packaged $variant internet permission does not match explicit app metadata" >&2; exit 1;
  }
  actual_notifications=false
  if grep -Eq "^uses-permission: name='android.permission.POST_NOTIFICATIONS'" "$evidence/$variant-permissions.txt"; then actual_notifications=true; fi
  [[ "$actual_notifications" == "$expected_notifications" ]] || {
    echo "Packaged $variant notification permission does not match explicit app metadata" >&2; exit 1;
  }
done
# Synthetic login credentials belong only to the separate instrumentation APK.
# A debug CA must never appear in release resources or its manifest, even when
# all variants are assembled together with the explicit local-proof property.
for packaged in "$apk" "$release_apk" "$bundle"; do
  if unzip -p "$packaged" | LC_ALL=C grep -aF 'Android-reference-only-2026!' > /dev/null; then
    echo "Synthetic account test password was packaged into an application artifact" >&2; exit 1
  fi
done
if grep -Eq 'agentc_test_ca|agentc_test_network_security|networkSecurityConfig' "$evidence/release-resources.txt" "$evidence/release-manifest.txt" ||
    grep -Eq 'agentc_test_ca|agentc_test_network_security' "$evidence/bundle-entries.txt"; then
  echo "Local account test trust leaked into a release artifact" >&2; exit 1
fi
build_id() { "$ANDROID_NDK_TOOLCHAIN/llvm-readelf" -n "$1" | awk '/Build ID:/ { print $3 }'; }
while IFS= read -r abi; do
  [[ -n "$abi" ]] || continue
  android_configure_abi "$abi" "$(setting minSdk)"
  mkdir -p "$evidence/$abi"
  cp "$project_root/build/android-$ANDROID_ABI_SLUG/asset_pipeline_app.dependencies.manifest" "$evidence/$abi/dependencies.manifest"
  cp "$project_root/build/android-$ANDROID_ABI_SLUG/asset_pipeline_app.dependencies-files.sha256" "$evidence/$abi/dependencies-files.sha256"
  grep -Fxq 'format=asset-pipeline-android-deps-v2' "$evidence/$abi/dependencies.manifest"
  grep -Fxq "abi=$abi" "$evidence/$abi/dependencies.manifest"
  grep -Fxq "api=$(setting minSdk)" "$evidence/$abi/dependencies.manifest"
  library="$evidence/$abi/libasset_pipeline_app.so"
  unzip -p "$apk" "lib/$abi/libasset_pipeline_app.so" > "$library"
  unzip -p "$bundle" "BUNDLE-METADATA/com.android.tools.build.debugsymbols/$abi/libasset_pipeline_app.so.dbg" > "$evidence/$abi/libasset_pipeline_app.so.dbg"
  unzip -p "$bundle" "base/lib/$abi/libasset_pipeline_app.so" > "$evidence/$abi/bundle.so"
  unzip -p "$release_apk" "lib/$abi/libasset_pipeline_app.so" > "$evidence/$abi/release.so"
  [[ -s "$evidence/$abi/libasset_pipeline_app.so.dbg" ]]
  "$ANDROID_NDK_TOOLCHAIN/llvm-readelf" -h -d -n "$library" > "$evidence/$abi/elf.txt"
  "$ANDROID_NDK_TOOLCHAIN/llvm-nm" --dynamic --defined-only "$library" > "$evidence/$abi/symbols.txt"
  grep -q "Machine:.*$ANDROID_ELF_MACHINE" "$evidence/$abi/elf.txt"
  for symbol in JNI_OnLoad crystal_android_host_render_slug crystal_android_host_render_slug_bytes crystal_ui_string_callback_dispatch_bytes crystal_android_host_lifecycle \
    crystal_android_host_navigation_back Java_dev_assetpipeline_androidhost_CrystalBridge_navigationBackNative \
    crystal_android_host_sheet_transition Java_dev_assetpipeline_androidhost_CrystalBridge_completeSheetTransitionNative \
    crystal_android_host_callback_void crystal_android_host_callback_string crystal_android_host_callback_bool \
    crystal_android_host_callback_float crystal_android_host_callback_int android_exception_pending \
    android_layout_prepare android_layout_wrap android_stack_set_alignment android_layout_add_spacer android_scrollview_configure \
    android_view_state_metadata android_view_semantics android_dialog_configure android_sheet_configure android_sheet_request_dismiss \
    crystal_android_service_complete crystal_android_service_pending_count \
    android_host_storage_submit android_host_http_submit android_host_secrets_submit android_host_files_submit android_host_notifications_submit android_host_service_cancel android_host_request_render \
    Java_dev_assetpipeline_androidhost_PrivateFiles_executeNative \
    Java_dev_assetpipeline_androidhost_CrystalServices_completeNative; do
    grep -q " T $symbol\$" "$evidence/$abi/symbols.txt" || {
      echo "Android library is missing required runtime export: $symbol" >&2; exit 1;
    }
  done
  if grep -Eq 'Homebrew|/opt/homebrew|\.dylib|libssl|libcrypto|libxml' "$evidence/$abi/elf.txt"; then
    echo "Unexpected host/server dependency in Android ELF" >&2; exit 1
  fi
  expected="$(build_id "$project_root/build/android-$ANDROID_ABI_SLUG/libasset_pipeline_app.so")"
  [[ -n "$expected" && "$(build_id "$library")" == "$expected" ]]
  [[ "$(build_id "$evidence/$abi/bundle.so")" == "$expected" ]]
  [[ "$(build_id "$evidence/$abi/release.so")" == "$expected" ]]
  [[ "$(build_id "$evidence/$abi/libasset_pipeline_app.so.dbg")" == "$expected" ]]
done < <(android_each_abi "$(setting abis)")
shasum -a 256 "$apk" "$release_apk" "$bundle" > "$evidence/artifact-sha256.txt"
echo "PASS: selected ABIs, packaged ELF/JNI exports and matching native debug symbols"
