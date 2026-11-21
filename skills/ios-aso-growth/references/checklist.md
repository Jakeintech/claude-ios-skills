# Launch checklist (copy into the app's `docs/` and tick it off)

Mark each line ✅ done with evidence, ⚠️ done but unverified, ❌ open, or ⛔ blocked on a person.

## Strategy
- [ ] Competitor table: price points, free-tier caps, rating and count, privacy label, one win and one complaint each (dated, sourced)
- [ ] Download intents listed in users' words, each mapped to a keyword cluster, a caption and a custom product page
- [ ] One-sentence "why this instead of X" for the top 3 competitors
- [ ] Monetization call written with reasons (`monetization.md`); refusals recorded in the roadmap

## Metadata
- [ ] Name ≤ 30 with brand + head term; subtitle ≤ 30 with the second intent
- [ ] Keywords ≤ 100, no repeats of name/subtitle words, no competitor or trademark names
- [ ] Promotional text ≤ 170, written for the current season or event
- [ ] Description: the first 3 lines answer "why download"; then benefits by intent; plain-language glossary if the domain has jargon
- [ ] What's New written as benefits
- [ ] IAP display names carry intent words
- [ ] `scripts/check_store_fields.py` passes
- [ ] Localized listing for the top 4–6 storefronts by category revenue

## Visuals
- [ ] 10 iPhone screenshots: frames 1–3 = promise, differentiator, proof; real UI, realistic data
- [ ] Watch screenshots (if there's a Watch app) that don't look like the default template
- [ ] App Preview video (15–30 s; the first 3 s show the core action)
- [ ] Two documented polish passes (thumbnail size, dark mode, contrast, consistency, claim check)
- [ ] Featuring art, In-App Event cards, OG image, site hero

## Product page
- [ ] Custom product pages per intent/audience, linked from matching campaigns
- [ ] Product page optimization test planned (icon or frame 1)
- [ ] In-App Events scheduled for the next two seasonal moments
- [ ] Featuring nomination submitted ≥ 3 weeks ahead with art

## Trust and quality
- [ ] Privacy label matches the code; privacy manifests per target
- [ ] Accessibility Nutrition Labels filled in truthfully after on-device checks
- [ ] App Review notes explain sensitive APIs (HealthKit, NFC, camera, AI) and data use
- [ ] Rating prompt only after success moments; at most once per version; never gated
- [ ] Review replies planned for the first two weeks (daily)

## Site
- [ ] Promise, proof, benefits, comparison (dated), trust, pricing, FAQ by intent, call to action
- [ ] Smart app banner, OG image, schema.org, canonical; one page per "X alternative" / "import from X"
- [ ] Staged until the build it describes is live

## Red team
- [ ] Fresh-agent review of every public claim against code and captures; all findings fixed or recorded
