#!/usr/bin/env bash
# Install APK to connected adb device
# Usage: ./install.sh [debug|release] [abi]
#   type: debug (default) | release
#   abi : arm64-v8a (default) | armeabi-v7a | x86 | x86_64
#
# Notes:
#   - With multiple devices, use ANDROID_SERIAL=<serial> ./install.sh
#   - Triggers the corresponding build script if APK not found
set -euo pipefail

cd "$(dirname "$0")"

ADB="$HOME/Library/Android/sdk/platform-tools/adb"
[[ -x "$ADB" ]] || ADB="$(command -v adb)" || { echo "Error: adb not found"; exit 1; }

TYPE="${1:-debug}"
ABI="${2:-arm64-v8a}"

case "$TYPE" in
    debug)   FLAVOR_DIR="debug" ;;
    release) FLAVOR_DIR="release" ;;
    *) echo "Usage: $0 [debug|release] [abi]"; exit 1 ;;
esac

# Check device connection
if ! "$ADB" get-state >/dev/null 2>&1; then
    echo "Error: no adb device connected"
    echo "Hint: enable USB debugging, or start an emulator"
    exit 1
fi
echo "==> Target device: $("$ADB" get-serialno)"

# Find APK (match ABI first, fall back to any apk in dir)
APK_DIR="app/build/outputs/apk/fx/$FLAVOR_DIR"
APK="$(ls "$APK_DIR"/*"$ABI"*.apk 2>/dev/null | head -1 || true)"
if [[ -z "$APK" ]]; then
    APK="$(ls "$APK_DIR"/*.apk 2>/dev/null | head -1 || true)"
fi

# Build first if APK not found
if [[ -z "$APK" ]]; then
    echo "==> No prebuilt $TYPE APK found, building..."
    if [[ "$TYPE" == "debug" ]]; then
        ./build_debug.sh "$ABI"
    else
        ./build_release.sh "$ABI"
    fi
    APK="$(ls "$APK_DIR"/*"$ABI"*.apk 2>/dev/null | head -1 || true)"
    [[ -n "$APK" ]] || APK="$(ls "$APK_DIR"/*.apk 2>/dev/null | head -1 || true)"
fi

echo "==> Installing: $APK"
"$ADB" install -r "$APK"

echo ""
echo "==> Done. Enable the input method in system settings:"
echo "    Settings -> System -> Keyboard -> Manage keyboards -> Fcitx5 for Android"
