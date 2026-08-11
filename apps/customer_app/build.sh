#!/usr/bin/env bash
# Vercel build script — Vercel's build image has no Flutter SDK, so this
# fetches the stable channel (shallow clone) once, then builds the web app
# with the env vars set in the Vercel project as --dart-define values.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_DIR="$REPO_ROOT/apps/customer_app"
FLUTTER_DIR="$REPO_ROOT/.flutter-sdk"

if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web

# The Maps JS loader tag lives in plain HTML (not compiled by Dart), so swap
# the placeholder for the real key before building.
MAPS_KEY="${GOOGLE_MAPS_API_KEY:-AIzaSyDALPvPiay0_oC5ZrGoLMncE3skEqp4g6k}"
sed -i.bak "s#__GOOGLE_MAPS_API_KEY__#${MAPS_KEY}#" "$APP_DIR/web/index.html"
rm -f "$APP_DIR/web/index.html.bak"

cd "$APP_DIR"
flutter pub get
# Fall back to the ksvl-naturals values (same defaults baked into env.dart)
# so a build with no Vercel env vars set still works.
flutter build web --release \
  --dart-define=FIREBASE_API_KEY="${FIREBASE_API_KEY:-AIzaSyCiJCD3o4JTP0wQWS8h-h826YAoDh5bTiw}" \
  --dart-define=FIREBASE_APP_ID="${FIREBASE_APP_ID:-1:604154597035:web:6ffed3a2d690d5f780f1ee}" \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID="${FIREBASE_MESSAGING_SENDER_ID:-604154597035}" \
  --dart-define=FIREBASE_PROJECT_ID="${FIREBASE_PROJECT_ID:-ksvl-naturals}" \
  --dart-define=FIREBASE_AUTH_DOMAIN="${FIREBASE_AUTH_DOMAIN:-ksvl-naturals.firebaseapp.com}" \
  --dart-define=FIREBASE_STORAGE_BUCKET="${FIREBASE_STORAGE_BUCKET:-ksvl-naturals.firebasestorage.app}" \
  --dart-define=GOOGLE_MAPS_API_KEY="${MAPS_KEY}" \
  --dart-define=TWO_FACTOR_API_KEY="${TWO_FACTOR_API_KEY:-}" \
  --dart-define=TWO_FACTOR_OTP_TEMPLATE="${TWO_FACTOR_OTP_TEMPLATE:-OTP1}"
