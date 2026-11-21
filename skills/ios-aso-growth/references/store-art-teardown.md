# Store-art teardown: compare yours with the top 10 before you design

Store art is judged against the apps beside it in search, at thumbnail size. Never design
it alone. Run this every time before making or changing screenshots.

## 0. Order of work (learned the hard way)

1. **Improve the screens first.** Run an honest critique of the real app screens (a fresh
   agent with the captures and a best-in-class bar: hierarchy, word count, one colour for
   the one action, believable demo data). Fix, build, recapture. Store art can only be as
   good as the UI inside it; framing a weak screen makes a weak screenshot. (Reps,
   2026-11: the first art framed captures of UI we had already decided to change.)
2. **Tear down the top 10** (this page).
3. **Write the captions** with `ios-conversion-copy` (phrase bank, lint, blind panel).
4. **Write the art-direction brief** from the teardown, then design with two polish passes.
5. **Blind-rank yours among theirs** at thumbnail size before shipping.

## 1. Collect

```bash
python3 scripts/fetch_store_art.py /tmp/teardown \
  "hevy=1458862350" "strong=464254577" "fitbod=1041517543" "ladder workout" ... \
  --ours "myapp=<id>" --ours-dir path/to/proposed/frames --frames 6
```

Apple's public lookup API gives each app's `screenshotUrls`; the images come from
`is1–5-ssl.mzstatic.com`, which the network must allow. The script retries Apple's
rate limit (403/429). It also writes `summary.json` (rating, count, price, the opening of
the description) and `contact-sheet.html`, one row per app with yours first. Keep
competitors' images out of git and out of anything public: they're for internal analysis.

Pick the 10 by search, not by memory: the top results for your 3 head terms, plus the
category's chart leaders, plus any app that wins on your differentiator.

## 2. Tear down each set (frames 1–2 matter most)

For every app, note:
- **Caption:** words, size relative to the frame, weight, case, position.
- **Composition:** full phone vs **zoomed UI crop**; straight vs **tilted/bleeding** device;
  panoramic continuity across frames.
- **Hero moment:** the one thing you see first (a giant number, a person, a muscle map,
  a laurel, a bold word).
- **Proof:** ratings laurel, award, user count, press. Real only.
- **People and photography:** whose, how used.
- **Ground:** one consistent colour system, or each frame different; dark or light.
- **Watch, widgets, Live Activity:** shown or not.

## 3. Compare honestly (a fresh agent, blind)

Ask a fresh agent, with the contact sheet and the frames:
1. Rank all sets, yours included, on "would I tap this at thumbnail size", with a reason each.
2. Is ours too simple? What exactly reads weaker: caption scale, legibility of the UI,
   repeated composition, colour system, no proof, no hero moment, no motion.
3. What do all the leaders have that ours lacks?
4. What do the leaders have that we should NOT copy (it would break our positioning or
   the truth: fake proof, stock people, a social feed, "AI coach")?
5. A frame-by-frame art-direction brief that beats at least 8 of 10.

## 4. Patterns seen in strength-training leaders (US, 2026-11-21)

- **Huge caption type** filling a third of the frame (Hevy, Ladder, Fitbod, Setgraph,
  MacroFactor), often one or two bold words.
- **Zoomed or tilted UI** so the key element is readable at thumbnail size (Hevy frame 2,
  Gravl, Alpha Progression, Setgraph); full upright phones shrink the UI to noise.
- **A hero numeral as art** (Setgraph's rolling "90 · 105 · 120 — Hit your next PR.").
- **Proof in frame 1 or 2:** laurels with ratings and review counts (Hevy "Apps We Love",
  Fitbod "Editor's Choice · 250,000 reviews", Ladder's awards, Setgraph "67K+ lifters · 4.7",
  Gravl, Alpha Progression).
- **People:** coaches and athletes (Ladder, Gravl, Alpha, Fitbod, StrengthLog).
- **Muscle maps** (Fitbod, MacroFactor, Setgraph).
- **One consistent ground**, mostly dark.

## 5. What not to copy

Fake or borrowed proof; stock athletes when the app has no coaches; a feed when the app is
private by design; "AI coach" framing when users distrust it. Without ratings yet, use
trust facts you can prove ("No account · No ads · Data Not Collected") where the laurel
would go, and add the real laurel when the ratings exist.
