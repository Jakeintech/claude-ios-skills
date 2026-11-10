#!/bin/bash
# Re-export Apple's Xcode-provided Claude Code plugin (skills + Xcode MCP) into a
# local marketplace and (re)install it. Run after every Xcode or Xcode-beta update.
#
#   bash scripts/sync-xcode-plugin.sh            # uses Xcode-beta (newest docs/skills)
#   XCODE_APP=/Applications/Xcode.app bash scripts/sync-xcode-plugin.sh
set -euo pipefail

XCODE_APP="${XCODE_APP:-/Applications/Xcode-beta.app}"
DEV_DIR="$XCODE_APP/Contents/Developer"
MARKET="$HOME/.claude/local-marketplaces/apple-xcode"
PLUGIN="$MARKET/plugins/xcode-integration"

[ -d "$DEV_DIR" ] || { echo "No Xcode at $XCODE_APP" >&2; exit 1; }

SRC=$(DEVELOPER_DIR="$DEV_DIR" xcrun mcpbridge run-agent plugin path --plugin-format claude | tail -1)
[ -f "$SRC/.claude-plugin/plugin.json" ] || { echo "Export failed: $SRC" >&2; exit 1; }
BUILD=$(basename "$(dirname "$SRC")")

rm -rf "$PLUGIN"
mkdir -p "$MARKET/.claude-plugin" "$(dirname "$PLUGIN")"
cp -R "$SRC" "$PLUGIN"

# Pin the MCP bridge to the chosen Xcode so DocumentationSearch etc. serve that
# Xcode's (beta) docs, regardless of what xcode-select points at.
cat > "$PLUGIN/.mcp.json" <<JSON
{
  "mcpServers": {
    "xcode": {
      "type": "stdio",
      "command": "xcrun",
      "args": ["mcpbridge"],
      "env": { "DEVELOPER_DIR": "$DEV_DIR" }
    }
  }
}
JSON

# Version the plugin by Xcode build so reinstalls pick up changes.
python3 -I - "$PLUGIN/.claude-plugin/plugin.json" "$BUILD" <<'PY'
import json, sys
p, build = sys.argv[1], sys.argv[2]
d = json.load(open(p)); d["version"] = f"1.0.0+{build}"
json.dump(d, open(p, "w"), indent=2)
PY

cat > "$MARKET/.claude-plugin/marketplace.json" <<JSON
{
  "name": "apple-xcode",
  "owner": { "name": "Apple (exported locally from $XCODE_APP, build $BUILD)" },
  "plugins": [
    { "name": "xcode-integration", "source": "./plugins/xcode-integration",
      "description": "Apple's Xcode-provided skills and Xcode MCP tools (build $BUILD)" }
  ]
}
JSON

claude plugin marketplace add "$MARKET" >/dev/null 2>&1 || claude plugin marketplace update apple-xcode
claude plugin install xcode-integration@apple-xcode -s user 2>/dev/null \
  || claude plugin update xcode-integration@apple-xcode

echo "xcode-integration synced from $XCODE_APP (build $BUILD)."
echo "Restart Claude Code to load it."
