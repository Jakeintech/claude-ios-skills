#!/usr/bin/env bash
#
# capture-appstore-screens.sh — photograph the App Store screens in demo mode.
#
# Builds the app once for the simulator, then for each device launches it with the
# demo scenario (-demo 1 -now 2026-11-11T20:46:00Z) plus the launch option for each
# shot, and saves a screenshot to appstore/screenshots/raw/<kind>/<NN-slug>.png.
# Frame them afterwards with scripts/compose-appstore-screenshots.py (or `fastlane screenshots`).
#
# Order: what the app does first (the outcome screen), then the daily answer, the signature input,
# the wow view, the accessibility/night mode, the tools.
#
# Usage:
#   scripts/capture-appstore-screens.sh [iphone|ipad|all]     (default all)
# Env:
#   ONLY=tonight,planner   capture only these slugs
#   IPHONE="iPhone 18 Pro Max"  IPAD="iPad Pro 13-inch (M5)"  simulator names
#   SETTLE=4               seconds to wait after launch before the screenshot
#   SKIP_BUILD=1           reuse build/dd from the last run

set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

KIND="${1:-all}"
IPHONE="${IPHONE:-iPhone 18 Pro Max}"
IPAD="${IPAD:-iPad Pro 13-inch (M5)}"
SETTLE="${SETTLE:-4}"
DD="build/dd"
BUNDLE_ID="com.example.myapp"
DEMO=(-demo 1 -now 2026-11-11T20:46:00Z -onboarding 0)

# slug | launch arguments (after the demo ones) | appearance | extra seconds to settle (maps, 3D)
SHOTS=(
  "outcome|-screen results|dark|4"
  "daily|-tab today|dark"
  "input|-screen search|dark"
  "wow|-screen preview3D|dark|12"
  "night|-tab today -redNight 1|dark|3"
  "tools|-tab tools|dark"
)

udid_for() {
  xcrun simctl list devices available | grep -F "$1 (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/'
}

if [[ "${SKIP_BUILD:-0}" != "1" ]]; then
  echo "==> Building for the simulator"
  xcodegen generate >/dev/null
  xcodebuild build -project MyApp.xcodeproj -scheme MyApp -configuration Debug \
    -destination "generic/platform=iOS Simulator" -derivedDataPath "$DD" -quiet
fi
APP="$DD/Build/Products/Debug-iphonesimulator/MyApp.app"
[[ -d "$APP" ]] || { echo "error: $APP not built" >&2; exit 1; }

capture() { # kind device-name
  local kind="$1" name="$2" udid
  udid="$(udid_for "$name")"
  [[ -n "$udid" ]] || { echo "error: no simulator named '$name'" >&2; exit 1; }
  echo "==> $kind on $name ($udid)"
  scripts/sim-setup.sh "$name" >/dev/null
  # iPhone shows only the time. The iPad also shows the date, with today's weekday whatever the
  # override says, so the framing script crops the iPad status bar.
  xcrun simctl status_bar "$udid" override --time "9:41" --batteryState charged --batteryLevel 100 \
    --cellularMode active --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null
  xcrun simctl install "$udid" "$APP"
  local out="appstore/screenshots/raw/$kind"; mkdir -p "$out"
  [[ -z "${ONLY:-}" ]] && rm -f "$out"/*.png   # a full run replaces the set, so old numbering can't linger
  local i=0
  for spec in "${SHOTS[@]}"; do
    IFS='|' read -r slug args look extra <<<"$spec"
    i=$((i + 1))
    if [[ -n "${ONLY:-}" && ",$ONLY," != *",$slug,"* ]]; then continue; fi
    xcrun simctl ui "$udid" appearance "$look" >/dev/null
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    # shellcheck disable=SC2086
    # Shot arguments first: LaunchOptions reads the first occurrence, so a shot can override -now.
    xcrun simctl launch "$udid" "$BUNDLE_ID" $args "${DEMO[@]}" >/dev/null
    sleep $((SETTLE + ${extra:-0}))
    local file
    file="$(printf '%s/%02d-%s.png' "$out" "$i" "$slug")"
    xcrun simctl io "$udid" screenshot --type=png "$file" >/dev/null 2>&1
    echo "    $file"
  done
  xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
  xcrun simctl status_bar "$udid" clear >/dev/null || true
}

case "$KIND" in
  iphone) capture iphone "$IPHONE" ;;
  ipad)   capture ipad "$IPAD" ;;
  all)    capture iphone "$IPHONE"; capture ipad "$IPAD" ;;
  *) echo "usage: $0 [iphone|ipad|all]" >&2; exit 2 ;;
esac
echo "Done. Frame with: python3 scripts/compose-appstore-screenshots.py appstore/screenshots/raw appstore/screenshots/final"
