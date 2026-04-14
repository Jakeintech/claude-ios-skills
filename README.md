# claude-ios-skills

A [Claude Code](https://claude.ai/code) skill plugin for end-to-end iOS development — from `git init` to App Store and beyond. Encodes best-in-class Swift/SwiftUI patterns, autonomous design review, project scaffolding, App Store screenshots, submission automation, and post-launch operations.

## 13 Skills Across 4 Phases

### Develop

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-scaffold** | `/ios-scaffold MyApp` | Create a new iOS project with xcodegen, SwiftUI, Swift Testing, App Groups, brand book, and SDLC workflow |
| **ios-tdd** | Auto | Test-driven development with Swift Testing — write test, implement, verify, refactor |
| **ios-design-review** | Auto or `/ios-design-review` | Autonomous UI critique against Apple HIG, Liquid Glass, SF Symbols, accessibility, and your brand book |
| **ios-code-review** | `/ios-code-review` | Review code for memory leaks, concurrency safety, `@Observable` patterns, and xcodegen consistency |
| **ios-iterate** | `/ios-iterate "feedback"` | Rapid design iteration — screenshot, apply feedback, rebuild, auto-review, show before/after |

### Prepare

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-app-icon** | `/ios-app-icon` | Create layered Liquid Glass icon via IconComposer with computer-use automation and manual fallback |
| **ios-screenshots** | `/ios-screenshots` | Multi-stage pipeline: raw capture, device frames, marketing shots, upload-ready. Intermediates stored at every stage |
| **ios-store-listing** | `/ios-store-listing` | Generate optimized App Store metadata — name, subtitle, description, keywords, What's New. ASO-optimized |
| **ios-privacy** | `/ios-privacy` | Privacy manifest, nutrition labels, export compliance, age rating, App Review notes. Full compliance suite |

### Ship

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-testflight** | `/ios-testflight` | Archive, upload, manage beta groups and testers, collect feedback and crash reports |
| **ios-submit** | `/ios-submit` | Pre-submission checklist (12 checks), upload media/metadata, submit for review, monitor status |

### Operate

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-review-response** | Auto or `/ios-review-response` | Categorize rejections, draft Resolution Center responses, prepare appeals, guide resubmission |
| **ios-version-update** | `/ios-version-update` | Version bump, release notes from git log, screenshot refresh, metadata update, hand off to ship pipeline |

## The E2E Pipeline

```
/ios-scaffold MyApp
  │
  ├─ DEVELOP
  │   ├─ ios-tdd (auto)           — test-driven implementation
  │   ├─ ios-design-review (auto) — autonomous UI critique
  │   ├─ /ios-iterate "feedback"  — rapid design iteration
  │   └─ /ios-code-review         — pre-commit review
  │
  ├─ PREPARE
  │   ├─ /ios-app-icon            — layered Liquid Glass icon
  │   ├─ /ios-screenshots         — multi-device, multi-stage pipeline
  │   ├─ /ios-store-listing       — metadata, keywords, description
  │   └─ /ios-privacy             — manifest, labels, compliance, ratings
  │
  ├─ SHIP
  │   ├─ /ios-testflight          — archive, upload, beta test
  │   └─ /ios-submit              — verify everything, submit for review
  │
  └─ OPERATE
      ├─ ios-review-response      — handle rejections
      └─ /ios-version-update      — next release (loops back to DEVELOP)
```

## The Design Review Loop

Claude builds your UI, screenshots it, critiques it against Apple's standards, and fixes issues autonomously:

```
You: "Build the settings screen"
 |
 +--> Claude implements the SwiftUI view
 +--> XcodeBuildMCP compiles and deploys to simulator
 +--> iOS Simulator MCP takes a screenshot
 +--> ios-design-review agent critiques against:
 |      - Apple HIG (navigation, typography, layout, touch targets)
 |      - Liquid Glass (correct variants, no glass-on-glass)
 |      - SF Symbols (no emojis, correct weight/scale)
 |      - Brand book (your app's design identity)
 |      - Accessibility (contrast, VoiceOver, Dynamic Type)
 |
 +--> Low-impact screen? Auto-fix and re-review (up to 3x)
 +--> High-impact screen? Show you before/after for approval
```

## The Screenshot Pipeline

Four stages with intermediates stored at every step for manual override:

```
Stage 1: Raw Capture          → screenshots/raw/{device}/
  Boot simulators for all device classes, navigate to key screens, capture PNGs

Stage 2: Framed               → screenshots/framed/{device}/
  Add device bezels/frames via Playwright or ImageMagick

Stage 3: Marketing Shots      → screenshots/marketing/{device}/
  Brand colors, text captions, gradients from your brand book

Stage 4: Upload-Ready         → screenshots/appstore/{device}/
  Validated dimensions, organized for asc upload
```

Replace any file at any stage — the skill uses existing files instead of regenerating.

## Install

```bash
git clone https://github.com/Jakeintech/claude-ios-skills.git ~/Documents/GitHub/claude-ios-skills
cd ~/Documents/GitHub/claude-ios-skills
./install.sh
```

This will:
1. Symlink skills to `~/.claude/skills/ios-dev/`
2. Append iOS standards to `~/.claude/CLAUDE.md`
3. Install 3 MCP servers at user scope
4. Check for `asc` CLI (optional, for Ship & Operate skills)

### Requirements

- macOS with Xcode 26.3+
- Node.js (for MCP servers via npx)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- [Claude Code](https://claude.ai/code) CLI
- [asc CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI) (`brew install asc`) — optional but recommended for Ship & Operate

### MCP Servers (installed globally)

- **[XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP)** — Build, test, LLDB debug, deploy (59 tools)
- **[Apple Xcode MCP](https://developer.apple.com/)** — Native Xcode 26.3+ integration via `xcrun mcpbridge`
- **[iOS Simulator MCP](https://github.com/whitesmith/ios-simulator-mcp)** — Screenshots, UI hierarchy, tap/swipe, device management

## Quick Start

```bash
# Scaffold a new project
/ios-scaffold MyNewApp

# Develop features
# (ios-tdd and ios-design-review auto-invoke during work)
/ios-iterate "make the tab bar use Liquid Glass"
/ios-code-review

# Prepare for App Store
/ios-app-icon
/ios-screenshots
/ios-store-listing
/ios-privacy

# Ship
/ios-testflight
/ios-submit

# After launch
/ios-version-update
```

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  Layer 4: Per-Project (generated by ios-scaffold)    │
│  Brand book, roadmap, project CLAUDE.md              │
├──────────────────────────────────────────────────────┤
│  Layer 3: MCP Servers (3 global) + asc CLI           │
│  XcodeBuildMCP + Xcode MCP + iOS Sim + App Store CLI │
├──────────────────────────────────────────────────────┤
│  Layer 2: Skills (13 global)                         │
│  Develop (5) + Prepare (4) + Ship (2) + Operate (2) │
├──────────────────────────────────────────────────────┤
│  Layer 1: Global CLAUDE.md                           │
│  iOS standards, Swift conventions, Apple HIG         │
└──────────────────────────────────────────────────────┘
```

## iOS Standards Enforced

Appended to `~/.claude/CLAUDE.md` and applied across all iOS projects:

| Category | Standard |
|----------|----------|
| **Project** | xcodegen, iOS 18+, SwiftUI lifecycle, `Shared/` directory, App Groups |
| **State** | `@Observable`, `@MainActor`, async/await, no Combine |
| **Design** | Liquid Glass (navigation only), SF Symbols, 44pt touch targets, HIG |
| **Testing** | Swift Testing (`@Test`, `#expect`), TDD cycle, tags |
| **Accessibility** | VoiceOver, Dynamic Type, 4.5:1 contrast, from day one |
| **Code** | Swift 6, strict concurrency, no external dependencies by default |

## Contributing

PRs welcome. Skills are markdown files in `skills/` — easy to read, modify, and extend.

## License

MIT
