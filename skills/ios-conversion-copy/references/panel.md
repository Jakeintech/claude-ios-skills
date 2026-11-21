# The honest-feedback panel

A blind comparison run by a FRESH agent, so it never sees your reasoning or knows which
set is yours. Run it after the lint passes, and again after each revision.

## Prompt template (fill the brackets; send as the agent's whole prompt)

> You are a panel of five real people deciding whether to download an app from the App
> Store. You only see what's below. Be blunt; you are not being polite to anyone.
>
> Personas (from real reviews and forum posts, with their own words):
> [5 personas: name, segment, what they want in their words, what turns them off]
>
> Three apps in the same category. You see each app's screenshot captions in order;
> frames 1–2 are what you see in search results without swiping.
> - App A: [captions]
> - App B: [captions]
> - App C: [captions]
>
> For each persona:
> 1. From frames 1–2 only, which app do you tap to download, and why, in one sentence in
>    your own voice?
> 2. After seeing all frames, do you change your mind? Why?
> 3. Score every caption of every app 1–5 for Clarity (I know what I'd get), Desire (I
>    want that) and Belief (I believe it).
> 4. Quote any word you didn't understand, didn't believe, or found off-putting.
>
> Then, as the panel: the 3 weakest captions across all apps with a better line for each,
> written in the personas' words; and the single change that would most help each app.
> Return JSON: {"personas":[{"name","pick_first2","why","pick_all","switch_why",
> "scores":{"A":[[c,d,b],…],"B":…,"C":…},"flags":[…]}],"weakest":[{"app","caption","better"}],
> "advice":{"A","B","C"}}

## Running it

- Shuffle which letter your set gets each round; record the mapping yourself.
- The competitor set uses real lines (from their store page or description, cited), not
  your paraphrase.
- Include your previous version as the third set, so you can see whether you improved.
- **Pass bar:** your set is picked first on frames 1–2 by a majority of personas; every
  caption averages 3.5+ on Clarity and Belief across all personas, and 3.5+ on Desire
  among the personas it targets (a switcher frame isn't for the beginner); no caption is
  flagged as unclear by 2+ personas.
- **Don't take every suggestion.** Personas will ask for things the rules forbid (naming
  competitors in screenshots) or that aren't built. Record what you declined and why.
- Keep each round's JSON in `docs/marketing/panel-rounds/` so changes have reasons.

## Limits

A panel of simulated personas is a stand-in for people, not a measurement. It is good at
catching jargon, vagueness and disbelief; it cannot tell you a conversion rate. When real
data arrives (Product Page Optimization, custom product page conversion), it wins.
