---
name: ios-aso-growth
description: Make an iOS app win its App Store category, from "why would anyone download this?" to a nominated, well-rated listing. Covers download intent and positioning against named competitors, the monetization call (free with ads vs remove-ads vs freemium subscription vs lifetime, with a decision table), keywords and metadata with Apple's limits checked by script, screenshots and banners with polish passes, custom product pages, in-app events, rating prompts and review replies, featuring nominations and Apple Design Award fit, the marketing site, growth loops, and a red-team gate that every claim must pass. Use it whenever the user mentions ASO, App Store optimization, keywords, ranking, downloads, store listing, screenshots or banners, ads or pricing, "free vs paid", reviews or ratings, getting featured, launch, marketing pages, or asks why someone would pick their app over a competitor, even if they only say "make it rank".
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent WebSearch WebFetch
argument-hint: "[plan|keywords|monetization|assets|checklist|redteam]"
---

# iOS ASO and growth

The App Store page is the product's first screen. People decide in a few seconds from the
icon, name, subtitle, rating and the first three screenshots, mostly without reading.
Everything here serves one question, asked from the user's side: **why would I download
this instead of the app I already know?** If the answer isn't specific, no keyword fixes it.

Work in this order. Each step names the file it produces and the check it must pass.
Write every caption, subtitle and headline with `ios-conversion-copy` (phrase bank, lint,
blind persona panel); this skill decides what goes where, that one decides the words.

## 0. Ground rules (non-negotiable)

- **Every claim maps to shipped code.** Before a feature appears on the store page, site
  or nomination, find it in the code and on a capture. Unbuilt features are marked "(if X
  ships)" and left out until they do.
- **Competitor facts carry a date and a source.** Prices and ratings change weekly; say "as
  of <date>, US App Store". Apps often sell several price points at once; show them.
- **No fake proof.** No invented ratings, user counts, press logos or testimonials. Proof
  you can't fake (a privacy label, an import feature, a comparison table with sources) is
  stronger anyway.
- **Lengths are checked by script, never by eye** (`scripts/check_store_fields.py`). This
  caught over-limit fields twice on Reps.
- **Health, finance and kids apps:** copy is never diagnostic or promissory (Guideline 1.4.1,
  5.1.3). Say what the app shows, not what it will do to your body.
- **Red-team before shipping anything public** (section 10). Use a fresh agent with the
  files, not your conclusions.

## 1. Intent and positioning → `STRATEGY` page

1. List the 6–10 apps a user would compare (top search results for the head terms, Reddit
   "best X app" threads, the category chart). For each: price points, free tier limits,
   rating and count, privacy label, one thing it wins on, the complaints in its reviews.
2. Map **download intent**: what job is the person hiring the app for, in their words
   ("log my lifts fast", "follow 5/3/1", "prep for a meet")? Each intent becomes a keyword
   cluster, a screenshot caption and a custom product page.
3. Find the lane: where competitors are weak and you can be best (their complaints are
   your feature list). Write the one-sentence answer to "why this instead of X".
4. Decide what you will **not** do, and why. A lane is defined by its refusals.

Read `references/checklist.md` for the full launch checklist.

## 2. Monetization call → decision log

Read `references/monetization.md`. Short version:

- **Utilities with a privacy promise: no ads.** An ad SDK means tracking, an ATT prompt and
  losing "Data Not Collected". Ads interrupt the core loop, and editors rarely feature
  ad-supported utilities.
- **"Free with ads, $0.99 to remove"** suits high-frequency casual apps and games with
  large audiences. For a tool people use daily, it anchors the price at $0.99 and
  cannibalizes a subscription worth 30–80× more per payer.
- **Default for a tool:** a free tier more generous than the category leader's (no caps on
  the core job), a Pro subscription for what only you do, and a lifetime option priced at
  2.5–3× the annual plan (no server costs means no lifetime liability).
- IAP display names are indexed for search: name them with intent words ("Pro: Meet Prep
  & Recovery", not "Premium Tier 1").

## 3. Metadata and keywords → `appstore/listing.json`, `STORE_LISTING.md`

| Field | Limit | Indexed for search | Notes |
|---|---|---|---|
| App name | 30 | Yes, highest weight | Brand + the head term ("Reps: Gym Workout Tracker") |
| Subtitle | 30 | Yes | The second intent; never repeat name words |
| Keywords | 100 | Yes | Comma-separated, no spaces; no word already in name/subtitle |
| Promotional text | 170 | No | Rotate with events; editable without review |
| Description | 4000 | No (iOS) | Written for conversion; first 3 lines show before "more" |
| What's New | 4000 | No | Benefits, not changelog |
| IAP names | 30 | Yes | Use intent words |

Keyword method:
- Build clusters from intents, competitor names and subtitles, autocomplete suggestions
  and review language. Then score each word by popularity (Apple Search Ads shows 5–100
  for the account owner) against difficulty (the rating counts of the top 10 results).
- Launch on long-tail terms you can win ("powerlifting log", "rpe tracker"); move to head
  terms as ratings grow.
- **Never** use another app's name or a trademarked program in keywords (Guideline 2.3.7):
  "hevy", "strong", "531" and "nsuns" were all cut from Reps for this reason. A program
  name can appear in the description where it describes what's built in.
- Singular and plural forms don't both need a slot; Apple matches both.
- Localize. Each storefront has its own keyword field, and a translated listing is also a
  featuring criterion.
- Re-check every release: what you rank for (Search Ads, App Store Connect search terms in
  App Analytics) decides the next keyword swap.

## 4. Screenshots, banners and art → Design canvas, then `appstore/screenshots/`

- **The first three frames carry the decision.** Frame 1 states the core promise on the
  core screen; frame 2 shows the differentiator; frame 3 shows proof or the outcome.
- Captions: one line, 2–6 words, benefit first, sentence case, legible at thumbnail size
  (≥ 80 pt on a 1320 × 2868 frame). Match the intent keyword where it reads naturally.
- Real UI only, captured from the build with realistic demo data, never "1 min, 2 sets".
- One visual system across frames: same caption position, frame, background treatment.
  Use the app's own tokens; no stock photos of people.
- Include Apple Watch frames if there's a Watch app; Watch apps lose on the store when
  their screenshots look like the default template.
- Make them on a Claude Design canvas (Artifact quickstart, intent "design") with the real
  captures uploaded as assets. Then do **at least two polish passes**. Each pass reviews
  every frame against this list at thumbnail size and in dark mode, fixes, and re-renders:
  hierarchy, caption length, crop, safe areas, colour contrast, consistency, and the claim
  check. A one-shot set is never shipped.
- Also produce: the featuring art (hero, no text baked into the key image), In-App Event
  cards (1920 × 1080 and 3:4), the website OG image (1200 × 630), and the App Preview poster frame.

## 5. Product page features

- **Custom product pages** (up to 35): one per intent or audience (switchers, beginners,
  meet prep, coaches). Each gets its own screenshots and promo text, and is linked from the
  matching campaign or post. Assign keywords to them where App Store Connect offers it.
- **Product page optimization:** A/B test the icon or the first screenshot, with up to 3
  treatments. One variable at a time; run to significance.
- **In-App Events:** seasonal moments (New Year, a recap in December, a challenge month).
  Name ≤ 30, short description ≤ 50, long ≤ 120. Submit 2–3 weeks ahead with a featuring
  nomination for each.

## 6. Ratings and reviews

- Ask with `requestReview` only after a success moment (a saved workout, a record, a
  finished task), never at launch, mid-task, on a paywall or after an error. Apple shows the
  prompt at most 3 times in 365 days, so spend each one well: about one ask per version,
  at least 120 days apart, only after the 3rd success or the 4th active day.
- Never gate (ask "are you happy?" first and send only happy people to the store); that
  breaks Guideline 5.6.1.
- Reply to every 1–3★ review within a few days, specifically and without defending. Use the
  `ios-review-response` skill.
- Ship TestFlight builds to real users before launch so day one has ratings coming.

## 7. Featuring and awards

- **Featuring nominations** (App Store Connect › Featuring Nominations): choose App Launch,
  App Enhancements or New Content; write up to 1,000 characters; submit at least 3 weeks
  ahead (Apple says ideally up to 3 months). Strong art helps.
- Editors weigh user experience, UI design, accessibility (fill in Accessibility Nutrition
  Labels truthfully), localization and the product page. Apple says there is no checklist.
- **Apple Design Awards:** Delight and Fun, Inclusivity, Innovation, Interaction, Social
  Impact, Visuals and Graphics. Pick the one or two categories you can be the best example
  of, and build the hero moment for that category deliberately.

## 8. Website → `site/` (use `ios-site` to scaffold)

Order: one-line promise and App Store badge, then a proof strip, 4–6 benefit sections with
real captures, a comparison table (dated, sourced, honest including where you lose), the
privacy or trust block, pricing, an FAQ written from real intents ("How do I switch from
X?"), and a closing call to action.
- Add the `apple-itunes-app` smart banner meta tag, an OG image, schema.org
  `MobileApplication` and one page per high-intent search ("X alternative", "import from X").
- Stage a version that describes an unreleased build on a branch, and publish it with the
  release.

## 9. Growth loops

- **Share artifacts** made from the user's own data, carrying a small brand mark. A
  shareable workout card was the documented growth engine of a top fitness logger.
- **Switching:** import from competitors in one step, and export back in their format.
  Removing switching cost is a feature and a marketing message.
- **People who bring people:** coaches, teachers and team leads. A 1:1 link that makes the
  leader's job easier recruits their whole group.
- **Moments:** New Year and the December recap, each with an In-App Event.
- **Community, honestly:** answer questions as the developer, disclose it, never astroturf.

## 10. Red-team gate (before any public artifact)

Spawn a fresh agent with the files and this list; fix everything it confirms:
1. Each claim on the store page, site, nomination and screenshots: TRUE / FALSE /
   UNVERIFIABLE against the code and captures.
2. Each competitor fact: source and date present; other live price points disclosed.
3. Field lengths and keyword rules pass `scripts/check_store_fields.py`.
4. No trademark or competitor names in keywords; no diagnostic or guaranteed-result copy.
5. The privacy label matches the code (no SDKs, no network calls you don't declare).
6. Accessibility claims are backed by on-device checks (VoiceOver, Dynamic Type, contrast).
7. Internal consistency: Free vs Pro is the same on the site, the store, the paywall and the strategy.

## Lessons from apps that shipped

- Reps (strength log, 2026): no ads, generous free tier, Pro trainer; the comparison table
  uses privacy labels and free-tier caps (checkable). Red-team caught a false "3D guides for
  850 exercises" claim (true for 57), trademark keywords and unbuilt features in the copy.
- Image generation for share art: `ImageCreator` stops working in iOS 27, and the iOS 27
  Image Playground sheet runs on Private Cloud Compute. Draw art procedurally on the device
  from the user's own data if the app promises on-device AI.
