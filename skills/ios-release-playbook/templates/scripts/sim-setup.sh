#!/bin/bash
#
# sim-setup.sh — prepare an iOS simulator for MyApp verification and screenshots.
#
# Shuts down (and optionally erases) the named simulator, boots it, then
# pre-grants every permission `xcrun simctl privacy` supports for the app
# bundle id. Prints what cannot be pre-granted and how the demo seed
# sidesteps it.
#
# Usage:
#   scripts/sim-setup.sh <device-name> [--erase]
#
# Example:
#   scripts/sim-setup.sh 'iPhone 16e' --erase

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "Usage: $0 <device-name> [--erase]" >&2
  exit 64
}

DEVICE_NAME=""
ERASE=false
for arg in "$@"; do
  case "$arg" in
    --erase) ERASE=true ;;
    --help | -h) usage ;;
    *)
      if [[ -z "$DEVICE_NAME" ]]; then
        DEVICE_NAME="$arg"
      else
        echo "error: unexpected argument: $arg" >&2
        usage
      fi
      ;;
  esac
done
[[ -n "$DEVICE_NAME" ]] || usage

# --- Resolve bundle id from project.yml -------------------------------------
# The app target sets PRODUCT_BUNDLE_IDENTIFIER: $(BUNDLE_PREFIX).app
BUNDLE_PREFIX="$(awk '/^ *BUNDLE_PREFIX:/ { print $2; exit }' "$REPO_ROOT/project.yml")"
if [[ -z "$BUNDLE_PREFIX" ]]; then
  echo "error: could not read BUNDLE_PREFIX from $REPO_ROOT/project.yml" >&2
  exit 1
fi
BUNDLE_ID="${BUNDLE_PREFIX}.app"
echo "==> App bundle id: $BUNDLE_ID"

# --- Resolve the simulator UDID ---------------------------------------------
UDID="$(xcrun simctl list devices available | grep -F "$DEVICE_NAME (" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')"
if [[ -z "$UDID" ]]; then
  echo "error: no available simulator named '$DEVICE_NAME'" >&2
  echo "Available devices:" >&2
  xcrun simctl list devices available >&2
  exit 1
fi
echo "==> Simulator: $DEVICE_NAME ($UDID)"

# --- Shutdown / erase / boot --------------------------------------------------
echo "==> Shutting down (if booted)"
xcrun simctl shutdown "$UDID" 2>/dev/null || true

if [[ "$ERASE" == true ]]; then
  echo "==> Erasing simulator content and settings"
  xcrun simctl erase "$UDID"
fi

echo "==> Booting"
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
echo "==> Booted."

# --- Grant permissions ---------------------------------------------------------
# Services MyApp uses that `simctl privacy` supports:
#   location   tonight's light where you are (when-in-use)
#   calendar   Add to Calendar on a plan
#   photos     the result photo on a plan
#   camera     AR (the simulator has no camera; AR shows its designed fallback)
#   siri       App Intents
SERVICES=(location calendar photos camera siri)

echo "==> Granting permissions for $BUNDLE_ID"
for service in "${SERVICES[@]}"; do
  if xcrun simctl privacy "$UDID" grant "$service" "$BUNDLE_ID" 2>/dev/null; then
    echo "    granted: $service"
  else
    echo "    WARNING: could not grant '$service' (not supported by this Xcode's simctl?)" >&2
  fi
done

cat <<'EOF'

==> Not pre-grantable: notifications (asked on the first saved plan). Demo mode
    (-demo 1) seeds places, plans and forecast, so screenshots never need it.

EOF
echo "==> Done. '$DEVICE_NAME' is booted with permissions granted."
