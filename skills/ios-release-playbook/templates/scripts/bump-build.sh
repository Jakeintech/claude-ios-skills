#!/usr/bin/env bash
#
# bump-build.sh — set CURRENT_PROJECT_VERSION in project.yml and regenerate the project.
# Every target reads $(CURRENT_PROJECT_VERSION), so there is exactly one place to change.
#
# Usage:
#   scripts/bump-build.sh            # +1
#   scripts/bump-build.sh --set N    # explicit build number
#   scripts/bump-build.sh --dry-run  # show what would change

set -euo pipefail

DRY_RUN=0; SET_TO=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --set) SET_TO="${2:-}"; shift ;;
    --set=*) SET_TO="${1#--set=}" ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//' | tail -n +2; exit 0 ;;
    *) echo "error: unknown argument '$1'" >&2; exit 2 ;;
  esac
  shift
done
if [[ -n "$SET_TO" && ! "$SET_TO" =~ ^[0-9]+$ ]]; then
  echo "error: --set needs a positive integer, got '$SET_TO'" >&2; exit 2
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
YML="$REPO_ROOT/project.yml"
count="$(grep -cE '^\s*CURRENT_PROJECT_VERSION: "[0-9]+"' "$YML" || true)"
if [[ "$count" -ne 1 ]]; then
  echo "error: expected exactly one CURRENT_PROJECT_VERSION: \"<n>\" in project.yml, found $count" >&2; exit 1
fi
current="$(grep -oE 'CURRENT_PROJECT_VERSION: "[0-9]+"' "$YML" | grep -oE '[0-9]+')"
next="${SET_TO:-$((current + 1))}"
if [[ "$next" == "$current" ]]; then echo "CURRENT_PROJECT_VERSION already $current"; exit 0; fi
echo "CURRENT_PROJECT_VERSION: $current -> $next"
[[ "$DRY_RUN" -eq 1 ]] && { echo "dry run: nothing written"; exit 0; }

tmp="$(mktemp)"
sed -E "s/CURRENT_PROJECT_VERSION: \"$current\"/CURRENT_PROJECT_VERSION: \"$next\"/" "$YML" > "$tmp" && mv "$tmp" "$YML"
grep -q "CURRENT_PROJECT_VERSION: \"$next\"" "$YML" || { echo "error: edit did not land" >&2; exit 1; }
(cd "$REPO_ROOT" && xcodegen generate)
echo "Done. Commit project.yml before running fastlane beta."
