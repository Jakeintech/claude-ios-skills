#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills/ios-dev"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo "=== claude-ios-skills installer ==="
echo ""

# Step 1: Symlink skills
echo "1/3 Installing skills..."
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
echo "2/3 Updating global CLAUDE.md..."
MARKER="## iOS Development Standards"
if grep -q "$MARKER" "$CLAUDE_MD" 2>/dev/null; then
    echo "  iOS standards already present in $CLAUDE_MD — skipping"
else
    echo "" >> "$CLAUDE_MD"
    cat "$SCRIPT_DIR/CLAUDE.md" >> "$CLAUDE_MD"
    echo "  Appended iOS standards to $CLAUDE_MD"
fi

# Step 3: Install MCP servers
echo "3/3 Installing MCP servers..."

echo "  Installing XcodeBuildMCP..."
claude mcp add --scope user --transport stdio XcodeBuildMCP -- npx -y xcodebuildmcp@latest mcp 2>/dev/null || echo "  XcodeBuildMCP already configured or claude CLI not found"

echo "  Installing Apple Xcode MCP..."
claude mcp add --scope user --transport stdio xcode -- xcrun mcpbridge 2>/dev/null || echo "  Xcode MCP already configured or claude CLI not found"

echo "  Installing iOS Simulator MCP..."
claude mcp add --scope user --transport stdio ios-simulator -- npx -y ios-simulator-mcp@latest 2>/dev/null || echo "  iOS Simulator MCP already configured or claude CLI not found"

echo ""
echo "=== Installation complete ==="
echo ""
echo "Skills installed at: $SKILLS_DIR"
echo "MCP servers: XcodeBuildMCP, xcode (mcpbridge), ios-simulator"
echo ""
echo "Available commands:"
echo "  /ios-scaffold MyApp    — Create a new iOS project"
echo "  /ios-design-review     — Review UI against Apple HIG"
echo "  /ios-code-review       — Review code before commit"
echo '  /ios-iterate "feedback" — Rapid design iteration'
echo "  ios-tdd                — Auto-invoked during feature work"
