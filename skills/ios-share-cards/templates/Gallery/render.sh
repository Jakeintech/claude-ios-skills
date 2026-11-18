#!/bin/bash
# Builds the gallery tool and renders every style. macOS 15+, Xcode toolchain.
# Usage: ./render.sh [output-directory] [fonts]
set -euo pipefail
cd "$(dirname "$0")"
OUT="${1:-/tmp/share-card-gallery}"
BIN="$(mktemp -d)/gallery"
swiftc -parse-as-library -O -swift-version 5 *.swift -o "$BIN"
"$BIN" "$OUT" "${2:-}"
