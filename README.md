# claude-ios-skills

A Claude Code skill plugin for iOS development. Encodes best-in-class Swift/SwiftUI patterns, autonomous design review, and production-grade project scaffolding.

## What's Included

### 5 Skills
| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `ios-scaffold` | `/ios-scaffold MyApp` | Create a new iOS project with proper structure |
| `ios-design-review` | Auto or `/ios-design-review` | Autonomous UI critique against Apple HIG |
| `ios-tdd` | Auto | Test-driven development with Swift Testing |
| `ios-code-review` | `/ios-code-review` | Review code against iOS best practices |
| `ios-iterate` | `/ios-iterate "feedback"` | Rapid design iteration loop |

### 3 MCP Servers (installed globally)
- **XcodeBuildMCP** — Build, test, debug, deploy (59 tools)
- **Apple Xcode MCP** — Native Xcode integration via xcrun mcpbridge
- **iOS Simulator MCP** — Screenshots, UI interaction, device management

### Global iOS Standards
Appended to `~/.claude/CLAUDE.md` — non-negotiable conventions for all iOS projects.

## Install

```bash
./install.sh
```

This will:
1. Symlink skills to `~/.claude/skills/ios-dev/`
2. Append iOS standards to `~/.claude/CLAUDE.md`
3. Install 3 MCP servers at user scope

## Requirements
- macOS with Xcode 26.3+
- Node.js (for XcodeBuildMCP and iOS Simulator MCP via npx)
- xcodegen (`brew install xcodegen`)
- Claude Code CLI

## Architecture

```
┌─────────────────────────────────────────────────┐
│  Layer 4: Per-Project Templates                 │
│  Brand book, roadmap, project CLAUDE.md         │
├─────────────────────────────────────────────────┤
│  Layer 3: MCP Servers (3 global)                │
│  XcodeBuildMCP, Apple Xcode MCP, iOS Simulator  │
├─────────────────────────────────────────────────┤
│  Layer 2: Skill Plugin (5 global skills)        │
│  scaffold, design-review, tdd, code-review,     │
│  iterate                                        │
├─────────────────────────────────────────────────┤
│  Layer 1: Global CLAUDE.md                      │
│  iOS standards, Swift conventions, Apple HIG    │
└─────────────────────────────────────────────────┘
```

## License

MIT
