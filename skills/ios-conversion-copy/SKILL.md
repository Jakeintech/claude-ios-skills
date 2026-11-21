---
name: ios-conversion-copy
description: Write App Store screenshot captions, subtitles, promo text, paywall headlines, website heroes and in-app insight copy that make the right person think "yes, I want that" — and prove it before shipping. Builds a voice-of-customer phrase bank from reviews and forums, maps each frame to one job the user hires the app for, writes verb- or outcome-first lines in the user's own words, lints them, then runs an honest-feedback loop: a panel of skeptical user personas blind-compares your copy with competitors' and with your last version, and the copy iterates until it wins on stated reasons. Use whenever the user mentions captions, screenshots, taglines, headlines, hero copy, paywall copy, "why would anyone download this", copy that sounds like a feature list, or insight wording inside an app ("Climbing", "Below Usual"), even if they only say "this copy is weak".
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent WebSearch WebFetch
argument-hint: "[bank|write|panel|loop|insights]"
---

# Conversion copy that works

People don't download features. They download a job done ("know what to lift next"), a
fear removed ("never lose a set"), or a self they want to be ("stronger than last month").
Most weak store copy names the feature from the builder's side: "Counts in Fitness, too",
"See what's climbing", "Smart Sets". The fix is a process, not a better adjective.

Pairs with `ios-aso-growth` (keywords, assets, the red-team gate) and `ios-screenshots`
(making the images).

## The loop

```
bank → map → write → lint → panel → revise → (panel again) → truth gate → ship → A/B
```

Never skip the panel. Never ship from a single draft.

### 1. Phrase bank (voice of the customer) → `docs/marketing/phrase-bank.md`

- Mine 30–50 short verbatim phrases from competitor App Store reviews (1–3★ for pains,
  4–5★ for desires), Reddit and forum threads ("best X app", "X vs Y"), review aggregators
  and competitor marketing pages. Keep the URL with each.
- Group them by **segment** (beginner, program-follower, intermediate, specialist, device
  user, switcher, professional/coach) into desires, frustrations and turn-offs.
- Rank the **desire words** (verbs and adjectives) by frequency; mark the ones that are
  also search terms (in competitor titles and subtitles).
- Write 5 **jobs to be done**: "When I ___, I want to ___, so I can ___."
- Tools: WebSearch works where pages are blocked; tag secondhand quotes as such and check
  them before any goes into public copy.

### 2. Message map → one desire per frame

Frame 1 is the core job in the most-searched words. Frame 2 is the differentiator in the
user's words. Frames 3+ each take one remaining job, fear or proof. About 70–85% of
visitors never swipe past frames 1–2: they must carry the pitch alone. Read
`references/formulas.md`.

### 3. Write: 3–5 candidates per frame

Rules (evidence in `references/formulas.md`):
- **Verb first, or outcome first**, in the user's words: "Log every set in one tap",
  "Know what to lift next", "Never lose a set".
- **One idea per frame.** If it needs "and", split it.
- **About 6 words, about 32 characters**, readable at thumbnail size.
- **A number beats an adjective**: "in one tap", "Slept 5 hours?".
- **No internal names**: features, frameworks or partner brands ("Training Partner",
  "Fitness", "HealthKit", "e1RM"). Name the benefit those things give.
- **No hype or unsourced superlatives**: no "best", "#1", "ultimate", "smart", "AI-powered".
  "#1" needs a named source (Guideline 2.3.7); "AI" signals distrust in many categories.
- **No other apps' names** in screenshots or metadata (2.3.7). "Bring your history from
  any app" passes; naming the app doesn't.
- Questions work when they name the reader's moment: "Sore shoulder? Swap the lift."

### 4. Lint → `scripts/caption_lint.py`

Mechanical checks: length, verb or outcome first, jargon, hype, a phrase-bank search word
in at least half the captions, no repeated openers. Fix until it passes. Lint is the
floor, not the judgement.

### 5. Panel: honest feedback, blind → `references/panel.md`

Spawn ONE fresh agent (not you; it must not see your reasoning) with the panel prompt in
`references/panel.md`:
- 5 personas from the phrase bank's segments, each with their own words and turn-offs;
- three caption sets **blind-labelled** A/B/C: your candidate, a real competitor's lines
  (from their store page or description), and your previous version;
- each persona picks which app they'd download from frames 1–2 alone and says why in one
  sentence, scores every caption for clarity, desire and believability (1–5), and quotes
  any word they didn't understand or didn't believe.

**Pass bar:** your set wins or ties a majority of personas against the competitor; no caption
averages under 3.5 on any axis; no caption is flagged as unclear by two or more personas.

### 6. Revise and repeat

Rewrite only the failing captions, using the personas' own words. Run the panel again with
fresh agents. Stop at the pass bar or after 3 rounds; then pick the best and say what's
still weak.

### 7. Truth gate (ios-aso-growth §10)

Every caption maps to shipped code and a real capture. Delete "if X ships" frames until
it does.

### 8. Ship, then measure

Use Product Page Optimization for frame 1 (one variable at a time, up to 3 treatments) and
a custom product page per segment. A real conversion test overrides the panel.

## Inside the app: insight copy

The same rules apply to words on screen, plus:
- **Numbers before words.** Show the metric where the eye already is: a delta chip beside the
  weight ("+5 lb"), a gauge with last time and the best as ticks, not a sentence under it.
- **Units the user thinks in**: plates and pounds, not percentages, mid-task. Percent is for
  charts and recaps.
- **Verdict words must name the thing**: "Going up" next to "228 lb est. max · ▲16 lb · 3
  mo" beats a bare "Climbing".
- **Timing:** celebrate a record when it's earned (logged), and recap it after; don't
  announce a "possible record" mid-set as a sentence. Show it by position (the fill passes
  the best tick).
- Every sentence on screen must survive the question "would they miss it if it were gone?"

## Lessons from apps that shipped

- Reps (2026-11-21), the loop in practice: round 1 (nine phrase-bank captions vs Hevy's
  real lines and the old set) won every persona after all frames but only tied on frames
  1–2. The panel showed why: the Watch, "free" and "no account" were buried at frames
  7–9; "1RM" lost beginners; "Lift lighter" read as overriding the user's program. Round
  2 put the trust points in a sub-line on frame 1, restored the "and why" hook one persona
  named, made the sleep frame opt-in ("Rough night? Your call.") and cut to six frames:
  5 of 5 on frames 1–2. Evidence: `docs/marketing/panel-rounds/` in the Reps repo.
- Sub-lines under captions carry trust (platform, price model, privacy) without
  stealing the caption's one idea. Balance their wrapping so no word is orphaned.

- Reps (2026-11): the v1 captions ("One tap per set.", "Knows the next jump, and why.",
  "Counts in Fitness, too.") failed the lint 4 of 6 times, mostly for naming features.
  The research found real demand behind one of them: lifters complain when a rival's
  workouts don't fill their rings. The fix was the lifter's gain in their own words
  ("Lifting counts toward your rings"), not deleting the frame.
