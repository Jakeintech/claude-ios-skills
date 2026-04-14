#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills/ios-dev"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo "=== claude-ios-skills installer ==="
echo ""

# Step 1: Symlink skills
echo "1/4 Installing skills..."
if [ -L "$SKILLS_DIR" ]; then
    echo "  Removing existing symlink at $SKILLS_DIR"
    rm "$SKILLS_DIR"
elif [ -d "$SKILLS_DIR" ]; then
    echo "  ERROR: $SKILLS_DIR exists and is not a symlink. Remove it manually."
    exit 1
fi

mkdir -p "$(dirname "$SKILLS_DIR")"
ln -s "$SCRIPT_DIR" "$SKILLS_DIR"
echo "  Symlinked $SCRIPT_DIR -> $SKILLS_DIR"

# Step 2: Append iOS standards to global CLAUDE.md
echo "2/4 Updating global CLAUDE.md..."
MARKER="## iOS Development Standards"
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
    echo "  iOS standards already present in $CLAUDE_MD — skipping"
else
    echo "" >> "$CLAUDE_MD"
    cat "$SCRIPT_DIR/CLAUDE.md" >> "$CLAUDE_MD"
    echo "  Appended iOS standards to $CLAUDE_MD"
fi

# Step 3: Install MCP servers
echo "3/4 Installing MCP servers..."

echo "  Installing XcodeBuildMCP..."
claude mcp add --scope user --transport stdio XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp 2>/dev/null || echo "  XcodeBuildMCP already configured or claude CLI not found"

echo "  Installing Apple Xcode MCP..."
claude mcp add --scope user --transport stdio xcode -- xcrun mcpbridge 2>/dev/null || echo "  Xcode MCP already configured or claude CLI not found"

echo "  Installing iOS Simulator MCP..."
claude mcp add --scope user --transport stdio ios-simulator -- npx -y ios-simulator-mcp@latest 2>/dev/null || echo "  iOS Simulator MCP already configured or claude CLI not found"

# Step 4: Check for asc CLI
echo "4/4 Checking for asc CLI (App Store Connect)..."
if command -v asc &>/dev/null; then
    echo "  asc CLI found: $(which asc)"
else
    echo "  asc CLI not found. Install it for Ship & Operate skills:"
    echo "    brew install asc"
    echo "  Then configure your API key:"
    echo "    asc auth init"
    echo "  (Ship & Operate skills will work without asc but with reduced automation)"
fi

echo ""
echo "=== Installation complete ==="
echo ""
echo "Skills installed at: $SKILLS_DIR"
echo "MCP servers: XcodeBuildMCP, xcode (mcpbridge), ios-simulator"
echo ""
echo "DEVELOP:"
echo "  /ios-scaffold MyApp     — Create a new iOS project"
echo "  /ios-design-review      — Review UI against Apple HIG"
echo "  /ios-code-review        — Review code before commit"
echo '  /ios-iterate "feedback"  — Rapid design iteration'
echo "  ios-tdd                 — Auto-invoked during feature work"
echo ""
echo "PREPARE:"
echo "  /ios-app-icon           — Create layered Liquid Glass icon"
echo "  /ios-screenshots        — Generate App Store screenshots"
echo "  /ios-store-listing      — Generate metadata & keywords"
echo "  /ios-privacy            — Privacy manifest & compliance"
echo ""
echo "SHIP:"
echo "  /ios-testflight         — Archive, upload, beta distribute"
echo "  /ios-submit             — Full submission with pre-flight checks"
echo ""
echo "OPERATE:"
echo "  /ios-review-response    — Handle rejections & appeals"
echo "  /ios-version-update     — Prepare the next release"
