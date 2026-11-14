---
name: <app>-roadmap
description: Use at the start of every <App> session, and whenever the owner asks "where are we", "resume", "what's next", "what's left before submit" or about the release plan. Gives the roadmap (1.0.0 → 1.0.1 → 1.1.0), how to rebuild context from the repo, and the working rules past sessions learned the hard way.
---

# <App> roadmap and resume

The repo is the memory. This skill says where to look and what order things happen in; the facts
live in the files below. **Update the Roadmap section here, STATUS.md and DECISIONS.md whenever a
step finishes or a plan changes.** A new session trusts them.

## 1. Rebuild context (do this first, every session)

1. `CLAUDE.md` (rules), then `docs/SPEC.md` milestones.
2. `STATUS.md` (milestone table and Known gaps), then `DECISIONS.md` (every choice made without the owner, newest last).
3. `git log --oneline -20` and `git status`.
4. `git worktree list` and `git branch`. An agent's unmerged branch is work in flight: review it, run the tests, merge, push, then remove the worktree.
5. `xcrun simctl list devices | grep Claude`. Use only Claude-owned simulators.

## 2. Roadmap

`MARKETING_VERSION` in project.yml must equal `appstore/listing.json` › version.versionString. Build numbers
only go up; App Store Connect already has builds: <list>.

### 1.0.0 — <goal in the owner's words>

Done (<date>): …

Left, in order:
1. …
2. **Owner only** (see the global `ios-release-playbook` §9): tick the IAPs, enable App Services, set availability, press Submit.

### 1.0.1
- …

### 1.1.0
- …

## 3. Rules learned in this project

- Demo launch arguments: `-demo 1 -now <ISO> …` (list every key and what it does).
- Simulators: names, UDIDs, which device each screenshot set uses.
- App Store: app id, team id, which files are the source of truth, the dry-run-first rule.
- Anything that cost more than 15 minutes once.
