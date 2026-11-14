#!/usr/bin/env bash
#
# capture-watch-screens.sh — photograph the Apple Watch app in demo mode for App Store Connect.
#
# Builds the watch app once for the simulator, then launches it with the demo scenario plus
# one option per shot and saves appstore/screenshots/final/APP_WATCH_SERIES_10/<NN-slug>.png.
# A 46 mm Series 10 or later simulator gives 416 x 496 px, the APP_WATCH_SERIES_10 size.
# Watch screenshots are uploaded as they are (no frame, no caption):
#   ruby appstore/asc/screenshots.rb appstore/screenshots/final
#
# The shots follow the design's Watch board, one page each.
#
# Usage:
#   scripts/capture-watch-screens.sh
# Env:
#   WATCH="Apple Watch Series 12 (46mm)"   simulator name or UDID
#   PHONE="<UDID>"                         the iPhone simulator paired with WATCH; booted so the
#                                          watch doesn't show the red "iPhone disconnected" icon
#   SETTLE=8                               seconds to wait after launch
#   SKIP_BUILD=1                           reuse build/ddw from the last run

set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

WATCH="${WATCH:-Apple Watch Series 12 (46mm)}"
SETTLE="${SETTLE:-8}"
DD="build/ddw"
BUNDLE_ID="com.example.myapp.watchkitapp"
OUT="appstore/screenshots/final/APP_WATCH_SERIES_10"

# slug | launch arguments
SHOTS=(
  "now|-demo 1 -now 2026-11-11T20:46:00Z"
  "countdown|-demo 1 -now 2026-11-11T20:46:00Z -page countdown"
  "detail|-demo 1 -now 2026-11-11T20:46:00Z -page detail"
  "night|-demo 1 -now 2026-11-11T20:46:00Z -redNight 1"
)

if [[ "$WATCH" =~ ^[0-9A-Fa-f]{8}-([0-9A-Fa-f]{4}-){3}[0-9A-Fa-f]{12}$ ]]; then
  DEST="platform=watchOS Simulator,id=${WATCH}"
else
  DEST="platform=watchOS Simulator,name=${WATCH}"
fi

if [[ -z "${SKIP_BUILD:-}" ]]; then
  xcodegen generate >/dev/null
  xcodebuild -project MyApp.xcodeproj -scheme MyAppWatch -configuration Debug \
    -destination "$DEST" -derivedDataPath "$DD" build >/dev/null
fi
APP="$DD/Build/Products/Debug-watchsimulator/MyAppWatch.app"

if [[ -n "${PHONE:-}" ]]; then
  xcrun simctl boot "$PHONE" 2>/dev/null || true
  xcrun simctl bootstatus "$PHONE" -b >/dev/null
fi
xcrun simctl boot "$WATCH" 2>/dev/null || true
xcrun simctl bootstatus "$WATCH" -b >/dev/null
xcrun simctl install "$WATCH" "$APP"
# watchOS simulators don't support status bar overrides: the clock shows the Mac's time.

mkdir -p "$OUT"
n=1
for shot in "${SHOTS[@]}"; do
  IFS='|' read -r slug args <<<"$shot"
  xcrun simctl terminate "$WATCH" "$BUNDLE_ID" 2>/dev/null || true
  # shellcheck disable=SC2086
  xcrun simctl launch "$WATCH" "$BUNDLE_ID" $args >/dev/null
  sleep "$SETTLE"
  file="$OUT/$(printf '%02d' "$n")-$slug.png"
  xcrun simctl io "$WATCH" screenshot "$file" >/dev/null 2>&1
  echo "$file"
  n=$((n + 1))
done
