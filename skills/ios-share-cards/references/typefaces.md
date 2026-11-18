# Typefaces for share cards

Ten options, all shipping with iOS. The Words column is the serif-italic treatment the templates carry; an app whose design has no serif sets the words role to a medium sans in quotation marks instead (a three-line change in `words(_:)` and the quote style), which also removes the device caveat at the end. Code: `templates/Rendering/ShareCardTypeface.swift`. Mock-ups: `templates/Gallery/` with `./render.sh <dir> fonts`.

## The ten

| Name | Feel | Display | Text | Words | Hero scale | Title scale |
|---|---|---|---|---|---|---|
| Tall | Poster numbers, narrow and loud | SF Pro Compressed (hero), Condensed (titles) | SF Pro Condensed | New York Italic | 1.28 | 1 |
| Rounded | Friendly and soft | SF Rounded | SF Rounded | New York Italic | 1 | 1 |
| Plain | Neutral, like iOS itself | SF Pro | SF Pro | New York Italic | 1 | 1 |
| Wide | Confident, lots of air | SF Pro Expanded | SF Pro | New York Italic | 0.78 | 0.8 |
| Editorial | A magazine page | New York (semibold) | SF Pro | New York Italic | 0.94 | 1 |
| Avenir | Calm and geometric | Avenir Next | Avenir Next | Iowan Old Style Italic | 1 | 1 |
| Futura | Sharp, a little retro | Futura | Futura | Bodoni 72 Book Italic (×1.12) | 0.86 | 1 |
| Didot | High contrast, luxury | Didot | SF Pro | Didot Italic (×0.94) | 1 | 1 |
| DIN | Sporty, a timing board | DIN Condensed (hero), DIN Alternate | DIN Alternate | New York Italic | 1.25 | 1 |
| Mono | A receipt, technical | SF Mono (semibold) | SF Mono (×0.86) | New York Italic | 0.86 | 0.86 |

Clock (times in a list) is SF Mono in all but DIN, which uses DIN Alternate.

## How a style asks for type

Styles never name a font. They ask by size and the typeface decides:

```swift
Text("75").cardFont(176)                 // hero number: display face × hero scale
Text(title).cardFont(24, .semibold)      // title: display face × title scale
Text(place).cardFont(14, .medium)        // label: text face × text scale
Text(quote).cardWords(40)                // something a person said
Text("7:19").cardClock(11)               // a time
```

Sizes at or above 60 are hero numbers, at or above 20 titles, below that labels. The renderer puts the typeface in the environment once, so no style or shared piece needs to know which one is in use. The wordmark keeps its own face.

## Choosing the standard

1. Render every candidate on the same five cards with the app's demo data.
2. Put them on one page, side by side, with a line on what each feels like.
3. Recommend one and say why, and say which you would pass on and why (thin strokes over photos, a mood that fits a different kind of app).
4. Let the owner pick. The standard is everyone's.

Things that tend to hold: narrow faces make numbers louder and suit sport and fitness; a serif suits calm, reflective apps; high-contrast serifs (Didot) lose their thin strokes at small sizes; Apple advises against light weights generally [S2 in `sources.md`].

## A choice of font as a paid option

- The standard face is free. The rest are the paid choice.
- `effective(raw:isPro:)` returns the stored choice with the subscription and the standard without it. The stored choice is kept, so it returns if the subscription does.
- The font screen previews any face on the person's own latest record before asking for anything. Rows show a badge, not a lock that blocks looking.
- Reach it from Settings and from the share screen's options.
- Add one true line to the paywall when it ships. Do not describe it in the store listing as free.

## Tests worth having

- Every named font resolves: `UIFont(name:size:) != nil` for each PostScript name a face asks for. This catches typos and fonts a future iOS drops.
- Every face × style × shape × fixture renders at the exact size.
- The long fixture's sticker is not cut off at its bottom edge, in every face.
- Changing the face changes the image.
- Without the subscription the effective face is the standard for every stored value.
- One reference image per face.

## Device caveat

`IowanOldStyle-Italic` (Avenir's words) and `BodoniSvtyTwoITCTT-BookIta` (Futura's words) resolve in the iOS 27.3 simulator, but Apple's font list appears to tag them differently from the core system fonts. Confirm on a real device. If a custom font is missing, `Font.custom` falls back to the system font, so the card still renders.
