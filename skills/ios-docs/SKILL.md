---
name: ios-docs
description: Generate and maintain living documentation — architecture overview with Mermaid diagrams, API reference from source code, CHANGELOG from git history, CLAUDE.md drift detection. Run periodically to keep docs in sync.
disable-model-invocation: true
argument-hint: "[architecture|changelog|api|all]"
allowed-tools: Bash(*) Read Write Edit Glob Grep
---

# iOS Docs — Living Documentation Generator

Generate and maintain living documentation for your iOS project. Keeps architecture docs, API reference, and CHANGELOG in sync with the actual codebase.

## Usage

```
/ios-docs              → generate all documentation
/ios-docs architecture → architecture overview only
/ios-docs api          → API reference only
/ios-docs changelog    → CHANGELOG from git history only
```

## What It Generates

### Architecture Overview (`docs/architecture.md`)

Scan the project structure and generate:

**Component diagram (Mermaid syntax, renders on GitHub):**

```
graph TD
    App[QuotedAI App] --> AppState
    App --> ContentView
    AppState --> QuoteOracle
    AppState --> QuoteHistory
    QuoteOracle --> QuoteDataIndex
    NotificationService --> QuoteOracle
    Widget[QuotedWidget] --> AppState
    Widget --> QuoteOracle
```

**Data flow section:** How data moves from source to UI:
- Where data originates (local files, SwiftData, HealthKit, network)
- How it flows through models and services
- What the view layer receives

**Dependency map:** What imports what. Scan all Swift files for `import` statements and cross-module dependencies. Flag circular dependencies.

**Target structure diagram:** Read `project.yml` and document each target:
- Target name, type (app, extension, tests)
- Which `Shared/` directories are included
- Key entitlements and capabilities

**Generation steps:**
1. Run `find . -name "*.swift" -not -path "*/Build/*"` to enumerate source files
2. Scan import statements and group by module
3. Identify public types in `Shared/` (used across targets)
4. Generate Mermaid diagram from dependency relationships
5. Write `docs/architecture.md`

---

### API Reference (`docs/api-reference.md`)

Scan all Swift source files and document:

**For each public type (class, struct, enum, protocol, actor):**
- Type name and kind
- One-line purpose (from leading `///` doc comment if present, else infer from name + context)
- Key public properties
- Key public methods with signatures
- Conformances

**Organization:** Group by directory — mirror the source structure:
```
## Shared/Models
### QuoteOracle
### QuoteHistory
...

## Shared/Services
### NotificationService
...
```

**Generation steps:**
1. Glob all `*.swift` files
2. For each file, extract: type declarations, public properties, public methods, doc comments
3. Skip test files (`*Tests.swift`, `*UITests.swift`)
4. Skip generated files
5. Write `docs/api-reference.md`

---

### CHANGELOG (`CHANGELOG.md`)

Generate from git history following [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

## [Unreleased]

### Added
- ...

## [1.2.0] — 2026-03-15

### Added
- New feature X (commit: abc1234)

### Fixed
- Bug Y fixed (commit: def5678)
```

**Generation steps:**
1. `git tag --sort=-version:refname` to get version tags
2. For each version range, `git log v1.1.0..v1.2.0 --oneline` to get commits
3. Parse commit prefixes: `feat:` → Added, `fix:` → Fixed, `refactor:` → Changed, `remove:` → Removed
4. Group commits by prefix under their version
5. Add `[Unreleased]` section for commits since last tag
6. Write `CHANGELOG.md`

---

### CLAUDE.md Drift Detection

Compare current code structure against existing `CLAUDE.md`:

**Checks:**
- New public types in `Shared/` not documented in "Core Components" section → flag
- Types listed in CLAUDE.md that no longer exist → flag
- New top-level directories not mentioned in architecture description → flag
- New targets in `project.yml` not listed in CLAUDE.md → flag
- Build commands that reference non-existent schemes or targets → flag

**Steps:**
1. Read current `CLAUDE.md`
2. Extract component names from "Core Components" section
3. Scan `Shared/` for public types
4. Diff the two lists
5. Report: new types to add, removed types to clean up, structural changes

**On confirmation:** auto-update the "Core Components" section with detected additions.

---

## Drift Detection Process

Run drift detection before reporting completion:

1. Check if `docs/architecture.md` exists — if yes, compare component list against current source
2. Check if `docs/api-reference.md` exists — if yes, compare type list against current source
3. Check if `CHANGELOG.md` exists — if yes, compare latest version against git tags
4. Check `CLAUDE.md` — compare Core Components section against `Shared/` public types

Report all drift findings in a summary:
```
Drift detected:
  + QuoteSubcategory (new, not in docs)
  + NewsService (new, not in docs)
  - OldComponent (in docs, no longer in source)

Updated: docs/architecture.md, docs/api-reference.md, CLAUDE.md
```

## When to Run

- After completing a feature (captures what was added)
- Before a release (CHANGELOG, ensure docs are current)
- When onboarding new contributors (verify CLAUDE.md is accurate)
- After a major refactor (architecture diagram may have changed)

## Commit

After generating documentation:
```bash
git add docs/ CHANGELOG.md CLAUDE.md
git commit -m "docs: regenerate architecture, API reference, and CHANGELOG"
```
