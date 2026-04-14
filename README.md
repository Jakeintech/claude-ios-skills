# claude-ios-skills

A [Claude Code](https://claude.ai/code) skill plugin for end-to-end iOS development — from raw idea to App Store and beyond. 19 skills covering product intelligence, development, App Store preparation, submission, and post-launch operations.

## The Hive Mind

The flagship skill, `ios-prd`, takes a raw app idea and dispatches 5 specialist agents in parallel — each analyzing from their domain. Their outputs converge into a complete, buildable PRD.

```
You: "Golden Hour: sunrise/sunset widgets, daily photo capture, monthly recaps..."
  │
  ├─ Product Strategist → blue ocean analysis, competitive research, feature engineering
  ├─ Platform Engineer  → Apple framework detection, Live Activities, Dynamic Island, Shortcuts...
  ├─ Design Analyst     → screen inventory, navigation flow, Liquid Glass opportunities
  ├─ Data Architect     → SwiftData schema, persistence strategy, CloudKit sync
  └─ Growth & Compliance → monetization, permissions, privacy, App Store risks
      │
      └─ Synthesis → cross-review → complete PRD with architecture, data model, epics
```

The Platform Engineer autonomously identifies integrations you didn't ask for — "this is a time-bounded daily event, so you need Live Activities, Dynamic Island, Watch complications, Shortcuts, Focus Filters..."

## 19 Skills Across 6 Phases

### Conceive

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-prd** | `/ios-prd "idea"` | Hive mind PRD — 5 parallel analysts produce product vision, architecture, data model, epics, compliance |

### Develop

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-scaffold** | `/ios-scaffold MyApp` | Create project with xcodegen, SwiftUI, Swift Testing, App Groups, brand book |
| **ios-data-model** | `/ios-data-model` | SwiftData schema design — `@Model` classes, relationships, migrations, CloudKit prep |
| **ios-widget** | `/ios-widget "desc"` | WidgetKit specialist — timeline providers, refresh budgets, size families, interactions |
| **ios-tdd** | Auto | Test-driven development with Swift Testing |
| **ios-design-review** | Auto or manual | Autonomous UI critique — HIG, Liquid Glass, SF Symbols, accessibility, brand book |
| **ios-code-review** | `/ios-code-review` | Code quality + performance — memory, concurrency, `@Observable`, energy efficiency |
| **ios-iterate** | `/ios-iterate "feedback"` | Rapid design iteration — screenshot, apply, rebuild, auto-review, before/after |
| **ios-docs** | `/ios-docs` | Living documentation — architecture diagrams, API reference, CHANGELOG, drift detection |

### Prepare

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-app-icon** | `/ios-app-icon` | Layered Liquid Glass icon via IconComposer with computer-use automation |
| **ios-screenshots** | `/ios-screenshots` | 4-stage pipeline: raw capture, device frames, marketing shots, upload-ready |
| **ios-store-listing** | `/ios-store-listing` | ASO-optimized metadata — name, subtitle, description, keywords, What's New |
| **ios-privacy** | `/ios-privacy` | Privacy manifest, nutrition labels, export compliance, age rating, review notes |

### Ship

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-testflight** | `/ios-testflight` | Archive, upload, manage beta groups/testers, collect feedback |
| **ios-submit** | `/ios-submit` | 12-point pre-submission checklist, upload, submit, monitor review status |

### Operate

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-review-response** | Auto or manual | Categorize rejections, draft appeals, prepare resubmission |
| **ios-version-update** | `/ios-version-update` | Version bump, release notes, screenshot refresh, hand off to ship pipeline |

### Infrastructure

| Skill | Invocation | What It Does |
|-------|-----------|-------------|
| **ios-localize** | `/ios-localize es ja` | String catalogs, formatting audit, RTL verification, locale App Store listings |
| **ios-ci** | `/ios-ci` | GitHub Actions or Xcode Cloud — build, test, TestFlight upload on tag |

## The Full E2E Pipeline

```
/ios-prd "your app idea"
  │
  ├─ CONCEIVE (hive mind: 5 analysts → synthesis → cross-review → PRD)
  │   Output: brand book, architecture, data model, epics, permissions
  │
  ├─ /ios-scaffold AppName (pre-filled from PRD)
  ├─ /ios-data-model (SwiftData schema from PRD)
  ├─ /ios-widget (if widgets identified)
  │
  ├─ DEVELOP
  │   ios-tdd + ios-design-review + ios-iterate + ios-code-review
  │
  ├─ /ios-docs + /ios-localize + /ios-ci
  │
  ├─ PREPARE
  │   /ios-app-icon → /ios-screenshots → /ios-store-listing → /ios-privacy
  │
  ├─ SHIP
  │   /ios-testflight → /ios-submit
  │
  └─ OPERATE
      ios-review-response (if rejected)
      /ios-version-update → loops back to DEVELOP
```

## Knowledge Layer

Every skill that touches Apple frameworks carries:

- **Static references** — Info.plist keys, entitlements, permission string patterns, privacy API categories
- **Live doc fetching** — context7 MCP pulls current Apple documentation before making framework decisions

The `ios-prd` skill carries 3 reference files:
- `patterns.md` — 15 product patterns mapped to Apple integrations
- `frameworks.md` — 25+ framework matrix (permissions, entitlements, APIs, deprecations)
- `permissions.md` — Approved usage description strings that won't get rejected

## Install

```bash
git clone https://github.com/Jakeintech/claude-ios-skills.git ~/Documents/GitHub/claude-ios-skills
cd ~/Documents/GitHub/claude-ios-skills
./install.sh
```

This will:
1. Symlink 19 skills to `~/.claude/skills/ios-dev/`
2. Append iOS standards to `~/.claude/CLAUDE.md`
3. Install 3 MCP servers at user scope
4. Check for `asc` CLI (optional, for Ship & Operate)

### Requirements

- macOS with Xcode 26.3+
- Node.js (for MCP servers via npx)
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- [Claude Code](https://claude.ai/code) CLI
- [asc CLI](https://github.com/rudrankriyam/App-Store-Connect-CLI) (`brew install asc`) — optional, for Ship & Operate

### MCP Servers (installed globally)

- **[XcodeBuildMCP](https://github.com/getsentry/XcodeBuildMCP)** — Build, test, LLDB debug, deploy (59 tools)
- **[Apple Xcode MCP](https://developer.apple.com/)** — Native Xcode 26.3+ via `xcrun mcpbridge`
- **[iOS Simulator MCP](https://github.com/whitesmith/ios-simulator-mcp)** — Screenshots, UI hierarchy, tap/swipe

## Quick Start

```bash
# Start with an idea
/ios-prd "A minimalist habit tracker that correlates habits with HealthKit data"

# Scaffold the project (pre-filled from PRD)
/ios-scaffold HabitFlow

# Build features (TDD and design review auto-invoke)
/ios-data-model
/ios-iterate "make the dashboard feel more personal"
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
│  Layer 4: Per-Project (generated by ios-prd/scaffold)│
│  Brand book, data model spec, project CLAUDE.md      │
├──────────────────────────────────────────────────────┤
│  Layer 3: Tools                                      │
│  XcodeBuildMCP + Xcode MCP + iOS Sim + asc CLI       │
├──────────────────────────────────────────────────────┤
│  Layer 2: Skills (19)                                │
│  Conceive(1) Develop(8) Prepare(4) Ship(2)           │
│  Operate(2) Infrastructure(2)                        │
├──────────────────────────────────────────────────────┤
│  Layer 1: Global CLAUDE.md                           │
│  iOS standards, Swift 6, Apple HIG, Liquid Glass     │
└──────────────────────────────────────────────────────┘
```

## iOS Standards Enforced

Appended to `~/.claude/CLAUDE.md` across all projects:

| Category | Standard |
|----------|----------|
| **Project** | xcodegen, iOS 18+, SwiftUI lifecycle, `Shared/`, App Groups |
| **State** | `@Observable`, `@MainActor`, async/await, no Combine |
| **Design** | Liquid Glass (nav only), SF Symbols, 44pt targets, HIG |
| **Testing** | Swift Testing (`@Test`, `#expect`), TDD, tags |
| **Accessibility** | VoiceOver, Dynamic Type, 4.5:1 contrast, from day one |
| **Code** | Swift 6, strict concurrency, no external deps by default |

## Contributing

PRs welcome. Skills are markdown files in `skills/` — easy to read, modify, and extend.

## License

MIT
