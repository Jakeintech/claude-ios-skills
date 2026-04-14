#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_BASE="$HOME/.claude/skills"
CLAUDE_MD="$HOME/.claude/CLAUDE.md"

echo "=== claude-ios-skills installer (19 skills) ==="
echo ""

# Step 1: Symlink each skill individually
echo "1/4 Installing skills..."
mkdir -p "$SKILLS_BASE"

SKILL_COUNT=0
for skill_dir in "$SCRIPT_DIR/skills"/*/; do
    skill_name=$(basename "$skill_dir")
    target="$SKILLS_BASE/$skill_name"

    if [ -L "$target" ]; then
        rm "$target"
    elif [ -d "$target" ]; then
        echo "  WARNING: $target exists and is not a symlink — skipping"
        continue
    fi

    ln -s "$skill_dir" "$target"
    SKILL_COUNT=$((SKILL_COUNT + 1))
done

# Clean up old monolithic symlink if it exists
OLD_SYMLINK="$SKILLS_BASE/ios-dev"
if [ -L "$OLD_SYMLINK" ]; then
    rm "$OLD_SYMLINK"
    echo "  Removed old ios-dev symlink"
fi

echo "  Installed $SKILL_COUNT skills to $SKILLS_BASE/"

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
echo "$SKILL_COUNT skills installed at: $SKILLS_BASE/ios-*"
echo "MCP servers: XcodeBuildMCP, xcode (mcpbridge), ios-simulator"
echo ""
echo "CONCEIVE:"
echo '  /ios-prd "idea"          — Hive mind PRD from raw idea (5 parallel analysts)'
echo ""
echo "DEVELOP:"
echo "  /ios-scaffold MyApp      — Create a new iOS project"
echo "  /ios-data-model          — SwiftData schema design"
echo '  /ios-widget "desc"       — WidgetKit specialist'
echo "  /ios-design-review       — Review UI against Apple HIG"
echo "  /ios-code-review         — Review code before commit"
echo '  /ios-iterate "feedback"  — Rapid design iteration'
echo "  ios-tdd                  — Auto-invoked during feature work"
echo "  /ios-docs                — Generate living documentation"
echo ""
echo "PREPARE:"
echo "  /ios-app-icon            — Create layered Liquid Glass icon"
echo "  /ios-screenshots         — Generate App Store screenshots"
echo "  /ios-store-listing       — Generate metadata & keywords"
echo "  /ios-privacy             — Privacy manifest & compliance"
echo ""
echo "SHIP:"
echo "  /ios-testflight          — Archive, upload, beta distribute"
echo "  /ios-submit              — Full submission with pre-flight checks"
echo ""
echo "OPERATE:"
echo "  /ios-review-response     — Handle rejections & appeals"
echo "  /ios-version-update      — Prepare the next release"
echo ""
echo "INFRASTRUCTURE:"
echo "  /ios-localize            — Internationalization & string catalogs"
echo "  /ios-ci                  — CI/CD setup (GitHub Actions / Xcode Cloud)"
