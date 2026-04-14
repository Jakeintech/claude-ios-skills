# Conceive & Develop Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 6 new skills (ios-prd with hive mind architecture, ios-data-model, ios-widget, ios-docs, ios-localize, ios-ci), enhance 2 existing skills (ios-code-review with performance.md, ios-design-review with deeper accessibility), and update install.sh + README to reach 19 total skills.

**Architecture:** Each skill is a SKILL.md with YAML frontmatter. The ios-prd skill is the most complex — it carries 3 reference files and 5 agent prompt files. Domain skills (data-model, widget) carry their own reference.md files. Enhanced skills get new reference files alongside existing ones.

**Tech Stack:** Markdown (SKILL.md files), Shell (install.sh)

---

## File Structure

```
claude-ios-skills/
├── skills/
│   ├── ios-prd/
│   │   ├── SKILL.md                           # Hive mind orchestrator
│   │   ├── patterns.md                        # 15 product patterns → Apple integrations
│   │   ├── frameworks.md                      # Apple framework matrix
│   │   ├── permissions.md                     # Usage description string guide
│   │   └── agents/
│   │       ├── product-strategist.md          # Blue ocean + feature engineering
│   │       ├── platform-engineer.md           # Framework + integration detection
│   │       ├── design-analyst.md              # Screens, flows, identity
│   │       ├── data-architect.md              # SwiftData schema + persistence
│   │       └── growth-compliance.md           # Monetization + permissions + growth
│   ├── ios-data-model/
│   │   ├── SKILL.md                           # SwiftData specialist
│   │   └── swiftdata.md                       # Schema patterns reference
│   ├── ios-widget/
│   │   ├── SKILL.md                           # WidgetKit specialist
│   │   └── widgetkit.md                       # Widget patterns reference
│   ├── ios-docs/
│   │   └── SKILL.md                           # Documentation generator
│   ├── ios-localize/
│   │   └── SKILL.md                           # Internationalization
│   ├── ios-ci/
│   │   └── SKILL.md                           # CI/CD setup
│   ├── ios-code-review/
│   │   └── performance.md                     # NEW reference file (added to existing)
│   └── ios-design-review/
│       └── reference.md                       # MODIFIED (deeper accessibility added)
├── install.sh                                 # Updated for 19 skills
└── README.md                                  # Updated for 19 skills
```

---

### Task 1: ios-prd — SKILL.md (Orchestrator)

**Files:**
- Create: `skills/ios-prd/SKILL.md`

The orchestrator skill that parses the raw idea, dispatches 5 analyst agents, synthesizes outputs, runs cross-review, and produces the PRD.

- [ ] **Step 1: Create the skill file**

Create `skills/ios-prd/SKILL.md` with this content:

```yaml
---
name: ios-prd
description: Turn a raw app idea into a complete Product Requirements Document. Uses hive mind architecture — 5 specialist agents (product strategist, platform engineer, design analyst, data architect, growth/compliance) analyze the idea in parallel, then synthesize into a unified PRD with Apple framework recommendations, data model, epics, and compliance requirements. Use when starting any new iOS app.
disable-model-invocation: true
argument-hint: "[app idea description]"
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent WebSearch
effort: max
---

# iOS Product Requirements Document — Hive Mind

Turn a raw app idea into a complete, buildable PRD using 5 specialist analyst agents working in parallel.

## Input

Raw app idea via `$ARGUMENTS`. Can be anything from a sentence to a paragraph:
- "Golden Hour: sunrise/sunset widgets, daily photo capture, metadata tracking, monthly recaps, community submissions"
- "A habit tracker that uses HealthKit to correlate habits with health metrics"
- "Minimalist podcast player focused on walking commutes"

## Phase 1: Parse & Dispatch

### 1.1 Parse the Idea

Read the raw idea and create a structured brief:
- **Core concept:** one sentence distillation
- **Key features mentioned:** bulleted list
- **Implied features:** what the user probably wants but didn't say
- **Target audience:** who is this for

### 1.2 Dispatch 5 Analyst Agents

Dispatch ALL 5 agents in parallel using the Agent tool. Each agent receives:
- The raw idea
- The structured brief from 1.1
- Their specific analyst prompt from `${CLAUDE_SKILL_DIR}/agents/{analyst}.md`
- The patterns reference: `${CLAUDE_SKILL_DIR}/patterns.md`
- The frameworks reference: `${CLAUDE_SKILL_DIR}/frameworks.md`

Read each agent prompt file before dispatching:

```
Agent 1: Product Strategist
  prompt file: ${CLAUDE_SKILL_DIR}/agents/product-strategist.md
  model: default (needs web search for competitive analysis)

Agent 2: Platform Engineer
  prompt file: ${CLAUDE_SKILL_DIR}/agents/platform-engineer.md
  model: default (needs context7 for Apple docs)

Agent 3: Design Analyst
  prompt file: ${CLAUDE_SKILL_DIR}/agents/design-analyst.md
  model: sonnet (screen inventory is mechanical)

Agent 4: Data Architect
  prompt file: ${CLAUDE_SKILL_DIR}/agents/data-architect.md
  model: default (needs context7 for SwiftData docs)

Agent 5: Growth & Compliance
  prompt file: ${CLAUDE_SKILL_DIR}/agents/growth-compliance.md
  model: default (needs web search for App Store guidelines)
```

Wait for all 5 to complete.

## Phase 2: Synthesis

Merge all 5 analyst outputs into a unified draft PRD:

1. **Deduplicate** — multiple agents identify the same feature/integration → merge, keep the most detailed version
2. **Cross-reference** — verify consistency:
   - Every framework the Platform Engineer recommends has permissions from Growth & Compliance
   - Every entity the Data Architect defines supports features from the Platform Engineer
   - Every screen the Design Analyst proposes is technically feasible per Platform Engineer
   - Nothing violates the Product Strategist's hard boundaries
3. **Resolve conflicts** — if agents disagree:
   - Technical feasibility wins over design wishes
   - Hard boundaries win over feature suggestions
   - Compliance requirements are non-negotiable
   - Document the conflict and resolution
4. **Produce unified draft PRD** with sections A through F (see below)

## Phase 3: Cross-Review

Dispatch a second round — each analyst reviews the merged PRD for their domain:

```
Dispatch 5 review agents in parallel, each receiving the merged PRD:
- Product Strategist: "Does anything violate the boundaries? Are epics correctly prioritized?"
- Platform Engineer: "Are all features technically feasible? Any missing frameworks?"
- Design Analyst: "Is the screen inventory complete for all features?"
- Data Architect: "Does the schema support all features? Any missing relationships?"
- Growth & Compliance: "Does every framework have proper permissions? Any App Store risks?"
```

Incorporate review feedback. If no issues, finalize.

## Phase 4: Present to User

Present the complete PRD in these sections:

### Section A: Product Vision
- North Star statement
- Hard boundaries (what this app is NOT) — 5-8 items
- Soft boundaries (where to stretch carefully)
- Pillars (2-4 core domains)
- Design identity (color mood, typography feel, icon style, tone)
- Competitive landscape (from Product Strategist's blue ocean analysis)
- Blue ocean opportunities (what competitors all miss)

### Section B: Technical Architecture
- Framework matrix table: Framework | API | Info.plist | Entitlement | Privacy | iOS Version
- Platform integrations — split into:
  - Core features (what user asked for)
  - Autonomously identified integrations (with reasoning)
  - Considered & rejected (with reasoning)

### Section C: Data Model
- Entity diagram (ASCII or Mermaid)
- SwiftData `@Model` schema overview
- Persistence strategy (on-device, CloudKit, or hybrid)
- Sync strategy if applicable

### Section D: Epic Breakdown
- Numbered epics with build order
- Each tagged with: skill handoff, frameworks, complexity (low/medium/high)

### Section E: Compliance
- All permissions with usage description strings (from permissions.md patterns)
- Privacy manifest declarations
- Age rating assessment
- Export compliance determination

### Section F: Monetization & Growth
- Pricing model (free, freemium, subscription)
- Feature gating — which features are free vs premium
- Growth loops (organic virality, share moments, widget exposure)

Ask user to review and approve.

## Phase 5: Handoff

On approval, generate these files in the current directory:

1. `docs/product-vision/00-product-bounds.md` — pre-filled from Section A
2. `docs/product-vision/SDLC-WORKFLOW.md` — pre-filled with epics from Section D
3. `docs/product-vision/data-model-spec.md` — Section C for ios-data-model to consume
4. `docs/product-vision/widget-spec.md` — widget requirements for ios-widget (if applicable)
5. `docs/product-vision/framework-requirements.md` — Section B + E for ios-scaffold to consume

Report to user:
- "PRD complete. Run `/ios-scaffold {AppName}` to create the project."
- List which skills to run after scaffold: /ios-data-model, /ios-widget (if applicable)
- Summarize the epic build order
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-prd/SKILL.md
git commit -m "feat: add ios-prd skill — hive mind orchestrator with 5-phase PRD generation"
```

---

### Task 2: ios-prd — Reference Files (patterns, frameworks, permissions)

**Files:**
- Create: `skills/ios-prd/patterns.md`
- Create: `skills/ios-prd/frameworks.md`
- Create: `skills/ios-prd/permissions.md`

- [ ] **Step 1: Create patterns.md**

Create `skills/ios-prd/patterns.md` — the product pattern detector. Contains 15 patterns, each with: detection signals, Apple platform integrations to evaluate, complexity per integration, typical epic placement. Full content specified in the spec under "Reference Files > patterns.md". Include all 15 patterns with their full integration lists.

- [ ] **Step 2: Create frameworks.md**

Create `skills/ios-prd/frameworks.md` — the Apple framework matrix. Contains the full table from the spec with 25+ frameworks, each row having: Info.plist keys, entitlements, privacy manifest implications, latest API recommendation, deprecated APIs to avoid. Include the context7 fetch instructions at the top.

- [ ] **Step 3: Create permissions.md**

Create `skills/ios-prd/permissions.md` — the usage description string guide. Contains the rules and approved patterns for every permission type (camera, location when-in-use, location always, photos read, photos add, health, contacts, calendar, microphone, Face ID, motion, music, nearby interaction). Full content specified in the spec.

- [ ] **Step 4: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-prd/patterns.md skills/ios-prd/frameworks.md skills/ios-prd/permissions.md
git commit -m "feat: add ios-prd reference files — patterns, frameworks, permissions"
```

---

### Task 3: ios-prd — Agent Prompts (5 analysts)

**Files:**
- Create: `skills/ios-prd/agents/product-strategist.md`
- Create: `skills/ios-prd/agents/platform-engineer.md`
- Create: `skills/ios-prd/agents/design-analyst.md`
- Create: `skills/ios-prd/agents/data-architect.md`
- Create: `skills/ios-prd/agents/growth-compliance.md`

- [ ] **Step 1: Create product-strategist.md**

Create `skills/ios-prd/agents/product-strategist.md`:

```markdown
# Product Strategist Analyst

You are analyzing a raw iOS app idea as a Product Strategist. Your job is to identify the core value, market position, and feature opportunities.

## Input

- **Raw idea:** {idea}
- **Structured brief:** {brief}

## Your Analysis

### 1. Blue Ocean Research

Use web search to research the competitive landscape:
- Search for existing apps in this category on the App Store
- Identify the top 3-5 competitors and their key features
- Find what they ALL do (commodity features)
- Find what they ALL miss (the gap — this is the blue ocean)

Output a competitive landscape summary:
```
Competitor | Key Features | Strength | Weakness
```

### 2. Core Value Proposition

Based on the gap analysis:
- What is this app's unfair advantage?
- What makes it defensible (hard to copy)?
- What's the 10x better experience over existing options?
- Write the North Star: one sentence that every feature must pass

### 3. Feature Engineering

Given the core concept, what adjacent problems could this solve?
- What would make users tell their friends?
- What creates a daily ritual (not just occasional use)?
- What makes this feel personal (not generic)?
- What would users pay for (genuine premium value)?

### 4. Product Boundaries

**Hard boundaries** — 5-8 things this app is NOT:
- What's tempting to build but would dilute the product?
- What would make this "just another [category] app"?

**Soft boundaries** — where to stretch carefully:
- Adjacent features that complement the core without overreaching

### 5. Pillars & Epics

Identify 2-4 core pillars (domains the app operates in).
Break features into epics with recommended build order:
- What ships in v1? (minimum lovable product)
- What's v1.1? (quick wins after launch)
- What's v2? (the big differentiator)

### 6. User Personas & Journeys

- Who is the primary user? (one sentence)
- What's their daily interaction with this app?
- What triggers them to open it?
- What keeps them coming back?

## Output Format

Return a structured JSON-like report with all sections above. Be specific, not generic. Every recommendation should reference what you found in competitive research.
```

- [ ] **Step 2: Create platform-engineer.md**

Create `skills/ios-prd/agents/platform-engineer.md`:

```markdown
# Platform Engineer Analyst

You are analyzing a raw iOS app idea as a Platform Engineer. Your job is to identify every Apple framework and platform integration this app needs.

## Input

- **Raw idea:** {idea}
- **Structured brief:** {brief}
- **Patterns reference:** (loaded from patterns.md)
- **Frameworks reference:** (loaded from frameworks.md)

## Your Analysis

### 1. Pattern Detection

Read patterns.md. For each of the 15 patterns, evaluate:
- Does this app match this pattern? (yes/no/partial)
- If yes: which integrations from that pattern apply?
- For each applicable integration: complexity (low/medium/high), which epic it fits

### 2. Framework Matrix

For every framework this app needs:

```
Framework | Specific API | Info.plist Keys | Entitlements | Privacy Manifest | Min iOS | Why
```

CRITICAL: For every framework you recommend:
1. Use context7 resolve-library-id to find the framework documentation
2. Query context7 for the specific API you plan to recommend
3. Verify the API exists and is not deprecated
4. If a newer replacement exists, recommend that instead

### 3. Platform Integrations

**Core features** — directly implementing what the user asked for:
- List each with: framework, API, complexity

**Autonomously identified** — integrations you detected from patterns that the user didn't mention:
- List each with: which pattern detected it, why it fits, framework, complexity
- This is the high-value output — discoveries the user didn't think of

**Considered & rejected** — integrations you evaluated but don't fit:
- List each with: why it doesn't fit this app
- This proves thoroughness

### 4. Technical Constraints

Flag anything that affects architecture:
- Background processing limits
- Widget refresh budget constraints
- Location accuracy vs battery trade-offs
- Photo processing memory concerns
- CloudKit sync complexity

## Output Format

Return the framework matrix table, three integration lists (core, identified, rejected), and technical constraints. Be specific about APIs — not "use CoreLocation" but "use CLMonitor with CLCircularGeographicCondition for geofence-based triggers."
```

- [ ] **Step 3: Create design-analyst.md**

Create `skills/ios-prd/agents/design-analyst.md`:

```markdown
# Design Analyst

You are analyzing a raw iOS app idea as a Design Analyst. Your job is to identify the screen inventory, navigation flow, and design identity.

## Input

- **Raw idea:** {idea}
- **Structured brief:** {brief}

## Your Analysis

### 1. Screen Inventory

List every screen this app needs:
```
Screen Name | Purpose | Impact Level (high/low) | Key Components
```

High-impact screens: onboarding, main/home, primary action, purchase/paywall
Low-impact screens: settings, detail views, about, list items

### 2. Navigation Flow

- Primary navigation pattern: TabView, NavigationStack, or sidebar?
- How many root tabs/sections?
- Key navigation paths (user journeys as screen sequences)
- Modal presentations vs push navigation decisions

### 3. Design Identity

Based on the app's concept and audience:
- **Color mood:** warm/cool/neutral, suggested palette direction
- **Typography feel:** serif (editorial), rounded (friendly), default (professional)
- **Icon style:** SF Symbol weight and scale preferences
- **Tone of voice:** how the app speaks to users (playful, calm, professional, minimal)
- **Signature interaction:** what gesture or animation defines this app's personality

### 4. Widget Appearances

If the app has widgets:
- Which widget families make sense
- What content each size shows
- How the widget relates to the main app visually

### 5. iOS 26 Liquid Glass Opportunities

Where does Liquid Glass apply?
- Navigation bars, tab bars, floating buttons
- Which screens have media backgrounds where `.clear` variant fits
- Any morphing transitions between states

## Output Format

Return the screen inventory table, navigation diagram, design identity recommendations, and Liquid Glass plan. Focus on decisions, not decoration.
```

- [ ] **Step 4: Create data-architect.md**

Create `skills/ios-prd/agents/data-architect.md`:

```markdown
# Data Architect Analyst

You are analyzing a raw iOS app idea as a Data Architect. Your job is to design the data model, persistence strategy, and sync approach.

## Input

- **Raw idea:** {idea}
- **Structured brief:** {brief}

## Your Analysis

### 1. Entity Identification

List every data entity this app needs:
```
Entity | Key Properties | Relationships | Persisted? | Syncs?
```

Think about:
- What does the user create? (content, settings, preferences)
- What does the system generate? (scores, streaks, analytics)
- What comes from external sources? (API data, HealthKit, weather)
- What metadata is tracked? (timestamps, locations, device info)

### 2. SwiftData Schema

For each entity, design the @Model class:

```swift
@Model
final class EntityName {
    var property: Type
    @Relationship(deleteRule: .cascade) var children: [ChildEntity]
    @Attribute(.unique) var naturalKey: String
    @Transient var computed: Type
    
    init(...) { }
}
```

Use context7 to fetch current SwiftData documentation before designing:
1. resolve-library-id for "SwiftData apple developer"
2. Query for @Model, @Relationship, @Attribute patterns
3. Verify API availability

### 3. Persistence Strategy

- **On-device only** or **CloudKit sync**? (based on whether community/multi-device features exist)
- **App Group shared store** — which entities need to be accessible from widgets?
- **Store location** — default vs App Group container

### 4. Migration Planning

- v1 schema (what ships first)
- v2 anticipated changes (what's likely to be added in the next version)
- Migration approach: lightweight (additive only) or custom (schema changes)

### 5. Query Patterns

For each main screen/view, what data does it need?
```
View | Entities Queried | Predicate | Sort | Expected Count
```

Flag any potentially expensive queries (large datasets, complex predicates).

### 6. Photo/Media Metadata (if applicable)

If the app deals with photos or media:
- EXIF data extraction strategy
- Thumbnail generation and caching
- Storage size management
- Metadata schema (location, timestamp, camera settings, weather, tags)

## Output Format

Return entity list, SwiftData schema code, persistence strategy decision, migration plan, and query patterns. Be specific about types and relationships.
```

- [ ] **Step 5: Create growth-compliance.md**

Create `skills/ios-prd/agents/growth-compliance.md`:

```markdown
# Growth & Compliance Analyst

You are analyzing a raw iOS app idea as a Growth & Compliance analyst. Your job is to identify the monetization model, all required permissions, App Store compliance requirements, and organic growth strategies.

## Input

- **Raw idea:** {idea}
- **Structured brief:** {brief}
- **Frameworks reference:** (loaded from frameworks.md)
- **Permissions reference:** (loaded from permissions.md)

## Your Analysis

### 1. Monetization Strategy

Based on the app concept:
- **Model:** Free, Freemium, Subscription, One-time purchase?
- **Premium features:** What features are NATURALLY premium (not just gated free features)?
  - Premium should offer genuine additional value, not withhold core functionality
- **Price point:** What's reasonable for this category?
- **Free tier:** What makes the free tier excellent enough to attract users?

### 2. Permission Audit

For every Apple framework the app might use, check frameworks.md and list:

```
Permission | Info.plist Key | Usage Description String | When Requested
```

For each usage description string, follow the patterns in permissions.md:
- Start with app name
- State specific feature
- Explain user benefit
- No jargon

### 3. Privacy Manifest

Based on likely framework usage:
- Which required-reason APIs will the code use? (UserDefaults is almost guaranteed)
- What data types are collected?
- Is any data linked to identity?
- Is any data used for tracking?

Output a draft privacy nutrition label.

### 4. Age Rating Assessment

Based on the app's content:
```
Category | Rating (None / Infrequent/Mild / Frequent/Intense) | Reasoning
```

### 5. Export Compliance

- Does the app use encryption beyond standard HTTPS?
- `ITSAppUsesNonExemptEncryption`: true or false?

### 6. App Store Risk Assessment

Review Apple's App Store Review Guidelines. Flag any potential risks:
- Content moderation requirements (if community features)
- In-app purchase requirements (if digital goods)
- Privacy requirements (if health/location data)
- Design requirements (if custom navigation)

### 7. Growth Loops

How does this app grow organically?
- **Share moments:** what does the user naturally want to share?
- **Widget virality:** friends see the widget on someone's phone
- **Word of mouth:** what makes users tell friends?
- **Referral hooks:** natural invite points
- **ASO keywords:** keywords that match the blue ocean positioning

## Output Format

Return monetization plan, full permission table with usage strings, privacy draft, age rating, export compliance, risk assessment, and growth strategy. Be thorough on permissions — missing a permission string causes App Store rejection.
```

- [ ] **Step 6: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-prd/agents/
git commit -m "feat: add ios-prd agent prompts — 5 hive mind analysts"
```

---

### Task 4: ios-data-model Skill

**Files:**
- Create: `skills/ios-data-model/SKILL.md`
- Create: `skills/ios-data-model/swiftdata.md`

The implementer should read the spec section "New Skill 2: ios-data-model" for the full SKILL.md content and the swiftdata.md reference content. The SKILL.md frontmatter:

```yaml
---
name: ios-data-model
description: Design SwiftData schema from PRD specification or app analysis. Generates @Model classes with relationships, indexes, migrations, CloudKit sync preparation, and test fixtures. Uses context7 for current SwiftData docs.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

The swiftdata.md reference covers: @Model patterns, ModelContainer for App Groups, #Predicate and FetchDescriptor, CloudKit restrictions, migration patterns, performance strategies.

- [ ] **Step 1: Read spec and create both files**
- [ ] **Step 2: Commit**

```bash
git add skills/ios-data-model/ && git commit -m "feat: add ios-data-model skill — SwiftData schema design with context7 docs"
```

---

### Task 5: ios-widget Skill

**Files:**
- Create: `skills/ios-widget/SKILL.md`
- Create: `skills/ios-widget/widgetkit.md`

Read spec section "New Skill 3: ios-widget". Frontmatter:

```yaml
---
name: ios-widget
description: Build WidgetKit widgets with proper timeline providers, refresh budgets, App Group data sharing, interactive elements, and size-adaptive layouts. Specialist for countdown, data-driven, and configurable widgets. Uses context7 for current WidgetKit docs.
disable-model-invocation: true
argument-hint: "[widget description]"
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

- [ ] **Step 1: Read spec and create both files**
- [ ] **Step 2: Commit**

```bash
git add skills/ios-widget/ && git commit -m "feat: add ios-widget skill — WidgetKit specialist with timeline patterns"
```

---

### Task 6: ios-docs Skill

**Files:**
- Create: `skills/ios-docs/SKILL.md`

Read spec section "New Skill 4: ios-docs". Frontmatter:

```yaml
---
name: ios-docs
description: Generate and maintain living documentation — architecture overview with Mermaid diagrams, API reference from source code, CHANGELOG from git history, CLAUDE.md drift detection. Run periodically to keep docs in sync.
disable-model-invocation: true
argument-hint: "[architecture|changelog|api|all]"
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

- [ ] **Step 1: Read spec and create the file**
- [ ] **Step 2: Commit**

```bash
git add skills/ios-docs/ && git commit -m "feat: add ios-docs skill — architecture, API reference, CHANGELOG, drift detection"
```

---

### Task 7: ios-localize Skill

**Files:**
- Create: `skills/ios-localize/SKILL.md`

Read spec section "New Skill 5: ios-localize". Frontmatter:

```yaml
---
name: ios-localize
description: Internationalize your iOS app — extract hardcoded strings into String Catalogs, audit date/number formatting for locale safety, generate translations, verify RTL layouts via simulator screenshots. Ties into ios-store-listing for locale-specific metadata.
disable-model-invocation: true
argument-hint: "[locale codes, e.g. es ja fr]"
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

- [ ] **Step 1: Read spec and create the file**
- [ ] **Step 2: Commit**

```bash
git add skills/ios-localize/ && git commit -m "feat: add ios-localize skill — string catalogs, formatting audit, RTL verification"
```

---

### Task 8: ios-ci Skill

**Files:**
- Create: `skills/ios-ci/SKILL.md`

Read spec section "New Skill 6: ios-ci". Frontmatter:

```yaml
---
name: ios-ci
description: Set up CI/CD for your iOS project — GitHub Actions or Xcode Cloud workflows for build, test, and TestFlight upload. One-time setup with branch protection and caching.
disable-model-invocation: true
allowed-tools: Bash(*) Read Write Edit Glob Grep
---
```

The SKILL.md body should include the exact GitHub Actions YAML from the spec as a template the skill generates.

- [ ] **Step 1: Read spec and create the file**
- [ ] **Step 2: Commit**

```bash
git add skills/ios-ci/ && git commit -m "feat: add ios-ci skill — GitHub Actions and Xcode Cloud CI/CD setup"
```

---

### Task 9: Enhance ios-code-review (performance.md)

**Files:**
- Create: `skills/ios-code-review/performance.md`

- [ ] **Step 1: Create performance.md**

Create `skills/ios-code-review/performance.md`:

```markdown
# Performance Review Reference

Additional checks for ios-code-review when reviewing performance-sensitive code.

## Main Thread Blocking

Detect synchronous work on `@MainActor` types:
- `Thread.sleep` or `usleep` on main actor
- Synchronous network calls (URLSession without async)
- Heavy computation in SwiftUI `body` property
- File I/O without `.task` or background actor
- Image decoding/resizing in view code

## Memory Audit

**Retain cycles in closures:**
- Closures stored as properties that capture `self` without `[weak self]`
- Timer callbacks, NotificationCenter observers, KVO without weak references
- `Task` closures that capture `self` — check if task is cancelled in `deinit`

**Large allocations:**
- Loading full-resolution images without downsampling (`UIImage(named:)` for large photos)
- Unbounded arrays growing without limits
- Caching without eviction policy

## Photo Pipeline

If the app processes photos:
- Thumbnail generation using `CGImageSourceCreateThumbnailAtIndex` (not full decode + resize)
- `preparingThumbnail(of:)` for async thumbnail generation
- Memory-mapped file access for large images
- Batch processing with autorelease pools

## Widget Efficiency

- Timeline entry count: don't generate more entries than needed
- Data fetching in `getTimeline`: use cached data when possible
- Shared `ModelContainer` via App Group (don't create new containers per refresh)
- Avoid network calls in timeline provider (use background app refresh to update data)

## Energy Efficiency

- Location updates: use `CLMonitor` (event-based) not `startUpdatingLocation` (continuous)
- Background tasks: respect `BGTaskScheduler` time limits
- Network: batch requests, use background URLSession for large transfers
- Animations: pause when app is backgrounded

## Instruments Tips

| Issue | Instruments Template |
|-------|---------------------|
| Slow UI / hitches | Time Profiler + Animation Hitches |
| Memory leaks | Leaks |
| Memory growth | Allocations |
| Energy drain | Energy Log |
| Network efficiency | Network |
| Core Data / SwiftData | Core Data |
| Widget timeline | WidgetKit Simulator |
```

- [ ] **Step 2: Update ios-code-review SKILL.md to reference it**

Add to the existing `skills/ios-code-review/SKILL.md`, after the existing process sections, a new line:

```markdown

## Performance Review

For performance-sensitive code (photo processing, widget timelines, background tasks), load the additional checklist from [performance.md](performance.md).
```

- [ ] **Step 3: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-code-review/
git commit -m "feat: add performance reference to ios-code-review — memory, energy, photo pipeline"
```

---

### Task 10: Enhance ios-design-review (deeper accessibility)

**Files:**
- Modify: `skills/ios-design-review/reference.md`

- [ ] **Step 1: Append accessibility depth to reference.md**

Add the following to the end of the existing `skills/ios-design-review/reference.md`, after the "iOS 26 Specific" section:

```markdown

### Deep Accessibility Audit

- [ ] VoiceOver navigation follows logical reading order (not visual layout order)
- [ ] Related elements grouped with `accessibilityElement(children: .combine)` or `.contain`
- [ ] Custom actions for complex interactions (`accessibilityAction`)
- [ ] Announcements for dynamic content changes (`UIAccessibility.post(notification:)`)
- [ ] Accessibility Inspector passes (run: Xcode > Open Developer Tool > Accessibility Inspector)
- [ ] Color blindness safe: test protanopia, deuteranopia, tritanopia (Simulator > Settings > Accessibility > Display > Color Filters)
- [ ] Reduced Motion: all animations gated behind `UIAccessibility.isReduceMotionEnabled` or `@Environment(\.accessibilityReduceMotion)`
- [ ] Reduced Transparency: glass effects degrade to solid backgrounds when enabled
- [ ] Minimum text size: no text below 11pt, all text respects `.dynamicTypeSize` environment
- [ ] Switch Control: all interactive elements reachable via switch scanning
- [ ] Voice Control: all buttons and controls have discoverable names
- [ ] Guided Access: app functions correctly with restricted areas
```

- [ ] **Step 2: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add skills/ios-design-review/reference.md
git commit -m "feat: deepen accessibility audit in ios-design-review reference"
```

---

### Task 11: Update install.sh and README

**Files:**
- Modify: `install.sh`
- Modify: `README.md`

- [ ] **Step 1: Update install.sh**

Update the skill count mention and the Available commands section to list all 19 skills organized by phase (Conceive, Develop, Prepare, Ship, Operate, Infrastructure). Change "1/4" to still be 4 steps (the process hasn't changed, just more skills are listed at the end).

The CONCEIVE section should be added before DEVELOP:
```
echo "CONCEIVE:"
echo "  /ios-prd \"idea\"        — Hive mind PRD from raw idea"
```

DEVELOP should add:
```
echo "  /ios-data-model         — SwiftData schema design"
echo "  /ios-widget \"desc\"      — WidgetKit specialist"
echo "  /ios-docs               — Generate living documentation"
```

Add INFRASTRUCTURE:
```
echo "INFRASTRUCTURE:"
echo "  /ios-localize           — Internationalization"
echo "  /ios-ci                 — CI/CD setup"
```

- [ ] **Step 2: Update README.md**

Update README to reflect 19 skills. Key changes:
- Title line: mention "19 skills"
- Add Conceive section with ios-prd
- Add ios-data-model, ios-widget, ios-docs to Develop section
- Add Infrastructure section with ios-localize, ios-ci
- Update architecture diagram to show 19 skills
- Add brief section on the Hive Mind architecture explaining the 5 analysts
- Update Quick Start to start with `/ios-prd`

- [ ] **Step 3: Commit**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git add install.sh README.md
git commit -m "docs: update install.sh and README for 19-skill toolkit"
```

---

### Task 12: Push and Verify

- [ ] **Step 1: Push**

```bash
cd ~/Documents/GitHub/claude-ios-skills
git push origin main
```

- [ ] **Step 2: Re-run install**

```bash
./install.sh
```

- [ ] **Step 3: Verify all 19 skills are listed**

Check that the install output shows all 19 skills across Conceive, Develop, Prepare, Ship, Operate, and Infrastructure.

---

## Self-Review

- [x] **Spec coverage:** All 6 new skills covered (Tasks 1-8). Both enhanced skills covered (Tasks 9-10). Install + README (Task 11). Push + verify (Task 12). ios-prd has all 9 files (SKILL.md + 3 references + 5 agent prompts) across Tasks 1-3.
- [x] **Placeholder scan:** No TBDs. Tasks 4-8 say "read spec and create" but provide exact frontmatter and reference the spec section for body content. The agent prompts in Task 3 are fully written out.
- [x] **Type consistency:** The ios-prd phases (Parse→Dispatch→Synthesis→Cross-Review→Present→Handoff) are consistent between SKILL.md and agent prompts. frameworks.md table schema matches what Platform Engineer outputs. permissions.md patterns match what Growth & Compliance uses.
