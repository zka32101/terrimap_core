#!/usr/bin/env bash
# 地図をブラウザで動かして確認する（Flutter Web ビルド → 配信 → Playwright）。CI には入れていない（重いため手動）。
# 前提: flutter、node、playwright（グローバル）、Chromium（PLAYWRIGHT_BROWSERS_PATH など）
set -euo pipefail
cd "$(dirname "$0")"
rm -rf packs && mkdir -p packs && cp -r ../packs/de ../packs/us packs/ && rm -f packs/*/profile.json
flutter pub get >/dev/null
flutter build web >/dev/null
(cd build/web && python3 -m http.server "${PORT:-8765}" >/dev/null 2>&1 & echo $! >../../.server_pid)
trap 'kill "$(cat .server_pid)" 2>/dev/null; rm -f .server_pid' EXIT
sleep 2
export NODE_PATH="${NODE_PATH:-$(npm root -g)}"
export DEMO_URL="http://localhost:${PORT:-8765}"
node e2e/map.e2e.mjs
