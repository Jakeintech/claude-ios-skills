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
