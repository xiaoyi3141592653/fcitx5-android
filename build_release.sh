#!/usr/bin/env bash
# Build release APK (fx flavor, auto-signed)
# Usage: ./build_release.sh [abi]
#   abi: arm64-v8a (default) | armeabi-v7a | x86 | x86_64 | all
#
# Signing key: keystore/release.jks is auto-generated on first run
# (personal use only, password embedded below)
set -euo pipefail

cd "$(dirname "$0")"

# JDK fallback (non-interactive shells may not source ~/.zshrc)
if [[ -z "${JAVA_HOME:-}" ]]; then
    export JAVA_HOME="$HOME/jdk/jdk-17.0.20.1+1/Contents/Home"
fi

KEYSTORE="keystore/release.jks"
KEY_ALIAS="fcitx5-android"
KEY_PWD="fcitx5-android"
STORE_PWD="$KEY_PWD"

# ---- Auto-generate signing key (first run only) ----
if [[ ! -f "$KEYSTORE" ]]; then
    echo "==> Signing key not found at $KEYSTORE, generating..."
    mkdir -p keystore
    "$JAVA_HOME/bin/keytool" -genkeypair \
        -keystore "$KEYSTORE" \
        -alias "$KEY_ALIAS" \
        -keyalg RSA -keysize 4096 -validity 36500 \
        -storepass "$STORE_PWD" \
        -keypass "$KEY_PWD" \
        -dname "CN=fcitx5-android, OU=personal, O=personal, L=local, ST=local, C=CN"
    echo "==> Key generated: $KEYSTORE (valid 100 years, back it up yourself)"
fi

ABI="${1:-arm64-v8a}"
if [[ "$ABI" == "all" ]]; then
    ABI_ARGS=()
    echo "==> Building Release APK (all ABIs)"
else
    ABI_ARGS=(-PbuildABI="$ABI")
    echo "==> Building Release APK (ABI: $ABI)"
fi

# Project reads signing config from these env vars
# (see build-logic/convention/src/main/kotlin/ProjectExtensions.kt)
export SIGN_KEY_FILE="$PWD/$KEYSTORE"
export SIGN_KEY_PWD="$KEY_PWD"
export SIGN_KEY_ALIAS="$KEY_ALIAS"

./gradlew :app:assembleRelease "${ABI_ARGS[@]}"

echo ""
echo "==> Build finished, artifacts:"
ls -lh app/build/outputs/apk/fx/release/*.apk 2>/dev/null || true

