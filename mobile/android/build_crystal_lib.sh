#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/../.." && pwd)"
asset_root="$project_root/lib/asset_pipeline"
[[ -f "$asset_root/src/ui/android/application.cr" ]] || {
  echo "Install the Android-capable AssetPipeline shard before building." >&2; exit 1;
}
[[ -f "$project_root/lib/amber/src/amber/native.cr" ]] || {
  echo "The installed Amber shard lacks amber/native. Use an Android-capable release or an explicit development override." >&2; exit 1;
}
source "$asset_root/scripts/android_env.sh"
setting() { awk -F= -v key="$1" '$1 == key { sub(/^[^=]*=/, ""); print; exit }' "$script_dir/android-app.properties"; }
export ANDROID_API="$(setting minSdk)"
export ANDROID_ABIS="$(setting abis)"
export CRYSTAL_CROSS_DEPS="${CRYSTAL_CROSS_DEPS:-$project_root/build/android-deps}"
export CRYSTAL_PATH="$project_root/lib:${CRYSTAL_PATH:-$(crystal env CRYSTAL_PATH)}"
"${CRYSTAL:-crystal}" run "$script_dir/validate_origin.cr"

# Dependency builds are source builds with verified archive caches. No JNI or
# renderer source is copied from a sample, and no Homebrew library is linked.
BUILD_DIR="$CRYSTAL_CROSS_DEPS" bash "$asset_root/scripts/cross_compile_deps.sh" android
while IFS= read -r abi; do
  [[ -n "$abi" ]] || continue
  android_configure_abi "$abi" "$ANDROID_API"
  ANDROID_ABI="$abi" BUILD_DIR="$project_root/build" \
    EXTRA_C_SOURCES="$asset_root/src/ui/native/android_bridge.c $asset_root/src/ui/native/jni_collection_bridge.c $asset_root/src/ui/native/android_private_files.c $asset_root/src/ui/native/android_host_jni.c" \
    bash "$asset_root/scripts/build_android.sh" "$project_root/src/platform/android/app.cr" asset_pipeline_app
  output_dir="$script_dir/app/src/main/jniLibs/$abi"
  mkdir -p "$output_dir"
  cp "$project_root/build/android-$ANDROID_ABI_SLUG/libasset_pipeline_app.so" "$output_dir/libasset_pipeline_app.so"
done < <(android_each_abi "$ANDROID_ABIS")
