---
name: ios-design-review
description: Autonomous UI design review against Apple HIG, Liquid Glass guidelines, SF Symbols, brand book, and accessibility standards. Use after building UI, or invoke manually to review the current screen.
allowed-tools: Bash(*) Read Glob Grep Edit
---

# iOS Design Review

Review the current UI against Apple HIG, Liquid Glass guidelines, and project standards.

## Reference Material

Load the full design checklist from [reference.md](reference.md) before reviewing.

## Process

### 1. Build & Screenshot
- Build the app using XcodeBuildMCP tools (or `xcodebuild build`)
- Boot the simulator if not running
- Launch the app on the simulator
- Take a screenshot of the current screen

### 2. Critique Against Standards

Review the screenshot and source code against these categories, in order:

**Apple HIG Compliance:**
- Navigation patterns, typography hierarchy, layout spacing, safe areas
- See the HIG Checklist in reference.md

**Liquid Glass Usage:**
- Glass on navigation layer ONLY (toolbars, tab bars, floating buttons)
- Correct variant: `.regular` for controls, `.clear` for media overlays
- No glass-on-glass stacking
- `GlassEffectContainer` wrapping multiple glass elements

**SF Symbols:**
- No emojis in UI — SF Symbols exclusively
- Correct weight and scale for context
- Consistent across the screen

**Brand Book Compliance:**
- Read `docs/product-vision/00-product-bounds.md` if it exists
- Check design identity section (colors, typography, icon style, tone)
- Verify the screen fits within product bounds

**Accessibility:**
- VoiceOver labels on interactive elements
- Dynamic Type support
- 4.5:1 contrast ratio minimum
- 44pt touch targets

### 3. Decision: Auto-fix or Pause

**Determine screen impact level:**
- **High-impact** screens: onboarding, main/home view, purchase/paywall, first-run experience
- **Low-impact** screens: settings, secondary detail views, about screens, list items

**If low-impact screen:**
- Apply fixes directly
- Rebuild and re-screenshot
- Run review again
- Loop up to 3 times, then report results

**If high-impact screen:**
- Do NOT auto-fix
- Present findings with the screenshot to the user
- List each issue with severity (blocker / warning / suggestion)
- Wait for user approval before making changes

### 4. Report Format

For each issue found:
```
[BLOCKER/WARNING/SUGGESTION] Category: Description
  File: path/to/file.swift:line
  Fix: specific change needed
```
