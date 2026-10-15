#!/usr/bin/env bash
# Builds the store releases: an Android App Bundle and an iOS archive (.ipa).
#
#   API_BASE_URL=https://api.example.com/api/v1 tool/build_release.sh [android|ios|all]
#
# Bump `version:` in pubspec.yaml before each store upload (the number after + must always increase).
set -euo pipefail
cd "$(dirname "$0")/.."

: "${API_BASE_URL:?Set API_BASE_URL to the production API, e.g. https://api.thenovatrix.com/api/v1}"
case "$API_BASE_URL" in https://*) ;; *) echo "API_BASE_URL must start with https://" >&2; exit 1 ;; esac
SITE_URL="${SITE_URL:-https://thenovatrix.com}"
target="${1:-all}"
defines=(--dart-define=API_BASE_URL="$API_BASE_URL" --dart-define=SITE_URL="$SITE_URL")

# Push notifications: pass the Firebase settings through when they're set (see README).
for name in FIREBASE_API_KEY FIREBASE_ANDROID_API_KEY FIREBASE_PROJECT_ID FIREBASE_SENDER_ID FIREBASE_IOS_APP_ID FIREBASE_ANDROID_APP_ID; do
  [[ -n "${!name:-}" ]] && defines+=(--dart-define="$name=${!name}")
done


flutter analyze
flutter test

if [[ "$target" == android || "$target" == all ]]; then
  [[ -f android/key.properties ]] || { echo "android/key.properties is missing: see README, Releasing." >&2; exit 1; }
  flutter build appbundle --release "${defines[@]}"
  echo "Android: build/app/outputs/bundle/release/app-release.aab"
fi
if [[ "$target" == ios || "$target" == all ]]; then
  flutter build ipa --release "${defines[@]}"
  echo "iOS: build/ios/ipa/ (upload with Xcode's Organizer or Transporter)"
fi
