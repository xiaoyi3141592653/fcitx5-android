#!/usr/bin/env bash
# Build debug APK (fx flavor, package org.fcitx.fcitx5.android.fx)
# Usage: ./build_debug.sh [abi]
#   abi: arm64-v8a (default) | armeabi-v7a | x86 | x86_64 | all
set -euo pipefail

cd "$(dirname "$0")"

# JDK fallback (non-interactive shells may not source ~/.zshrc)
if [[ -z "${JAVA_HOME:-}" ]]; then
    export JAVA_HOME="$HOME/jdk/jdk-17.0.20.1+1/Contents/Home"
fi

ABI="${1:-arm64-v8a}"
if [[ "$ABI" == "all" ]]; then
    ABI_ARGS=()
    echo "==> Building Debug APK (all ABIs)"
else
    ABI_ARGS=(-PbuildABI="$ABI")
    echo "==> Building Debug APK (ABI: $ABI)"
fi

./gradlew :app:assembleDebug "${ABI_ARGS[@]}"

echo ""
echo "==> Build finished, artifacts:"
ls -lh app/build/outputs/apk/fx/debug/*.apk 2>/dev/null || true
