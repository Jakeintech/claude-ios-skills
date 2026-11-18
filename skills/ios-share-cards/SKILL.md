---
name: ios-share-cards
description: Design and build social share cards for an iOS app — Instagram Story cards, transparent stickers for the person's own photo, 4:5 and 1:1 posts, recap cards — in a modern, clean, type-led style, with a full-screen style picker, the Instagram Stories hand-off, fonts people can choose, and tests. Use this whenever the user mentions share cards, share images, "share to Story", Instagram Stories, stickers or overlays, recap or wrapped cards, a share sheet or share card that looks dated, or wants an app's numbers, lists or quotes turned into something people post, even if they only say "make this shareable". Holds the design rules with their sources, the SwiftUI code that shipped (templates), a macOS tool that renders mock-ups, and a self-contained prompt for other tools.
allowed-tools: Bash(*) Read Write Edit Glob Grep Agent WebFetch
argument-hint: "[mock|build|review]"
---

# iOS share cards

A share card is a small poster the person posts for you. It is looked at for about a second, on a phone, at arm's length, usually inside another app's chrome. Everything here follows from that: few things, large, readable over whatever is behind them, and shaped for where they will land.

This skill carries the rules, the order of work, and code that shipped. Read `references/design-principles.md` before designing anything; it has the reasons and the sources.

## Arguments

- `mock`: steps 1 to 4 of the order of work. Stop at the gallery and the recommendation.
- `build`: steps 5 to 9, for styles the owner has already picked.
- `review`: judge an existing share flow against "What good looks like" and section 10 of the principles, with screenshots, and list what to change.

With no argument, start at step 1 and stop for the owner's pick after step 4.

## What good looks like

1. **One idea per card.** A card has a hero: one number, one line of words, one list, one chart or one photo. A card that tries to be the whole detail screen reads as a screenshot of a dashboard. Offer several simple styles instead of one dense one.
2. **Few, large things.** At most three numbers on a card. On a 360 pt wide canvas the smallest text is about 12.5 pt and hero numbers run 130 to 220 pt. No tiles, no dividers between stats, no icons as decoration.
3. **No boxes.** Text sits straight on the background. The only filled shapes are ones with a job: a caption bar over a photo, a sticker pill, a paper ticket.
4. **Type does the work.** One typeface family with four roles: display (numbers and titles), text (labels), words (a quote, in quotation marks: a serif italic or a medium sans, whichever the app's design has), clock (times, monospaced). Colour is the background; accents are one small mark.
5. **Readable over any photo.** Text never sits on a raw photo. Either darken under the text, haze the whole photo, or bring a solid bar. Hold white text at 4.5:1 on a pure white photo, by arithmetic, not by eye.
6. **Shaped for the destination.** Every card renders at Story 9:16, Post 4:5 and Square 1:1, at 1080 px wide. Story cards keep the top and bottom clear of the host app's controls.
7. **Stickers are transparent.** A sticker is sized by its content, has alpha, and uses only fills and soft shadows, because it cannot blur what another app puts behind it.
8. **The person's own data, always.** Previews, thumbnails and font samples are drawn with their class, run, trip or day. A style that needs something they do not have is left out, not greyed.
9. **Private by default.** Location detail, body numbers and anything about another person start off. Words before numbers where a number could feel like a score.

## Order of work

The owner picks from pictures before any app code is written. Mock-ups are cheap; a built screen nobody wanted is not.

1. **Look at what exists.** Find the current share flow, run the app with demo data, screenshot the share screen and each card. Say plainly what dates it (bordered panels, dense stat rows, cards that are not Story-shaped, a picker that is mostly controls).
2. **Map the app's data to archetypes.** See the table below. Aim for 10 to 12 styles ranging from very simple to rich, each with a one-line reason to exist.
3. **Mock with real type.** Copy `templates/Gallery/` somewhere outside the app targets, replace the demo content and wordmark, run `./render.sh <dir>`. It renders every style in every shape with SwiftUI's `ImageRenderer` on macOS, so fonts, gradients and SF Symbols are real. Use the app's real demo data. If photos are needed and none are available, draw stand-ins and say they are drawn.
4. **Show a gallery and recommend six.** One page: what exists, the family, the three shapes, over-any-photo, stickers, the picker, the code shape, free and paid, a build order. Recommend which six to build first and why. Say what is not verified.
5. **Build with the kit** once they pick. `templates/Rendering/` compiles as it stands for iOS 26 with Swift 6 strict concurrency. Replace `ShareCardContent` with the app's nouns, keep the protocol, registry and renderer.
6. **Build the picker** from `templates/Picker/`: a full-height pager of the live card, a strip of thumbnails, one shape control, an options sheet with at most three options per style, one main action.
7. **Wire the hand-off.** Read `references/instagram-handoff.md`. Flat Story cards go as the background image; stickers go as the sticker layer over the person's photo.
8. **Test** with `templates/Tests/`: every style × shape × typeface × three fixture classes (full, nearly empty, very long strings).
9. **Check on a phone** what the simulator cannot show, and say in the PR which checks are still open.

## Archetypes

Rename them for the app. The second column is what the app needs to have.

| Archetype | Needs | Example in the templates |
|---|---|---|
| One Number | any count or duration | `OneNumberStyle` |
| Caption (photo first, one thin bar) | a photo | `CaptionStyle` |
| Sticker: pill, stack, lower third | nothing | `PillSticker`, `StackSticker` |
| Ordered list ("the playlist from class") | items in order | `SetlistStyle` |
| One quote, set large | a saved line of text | `TeacherLineStyle` |
| One line chart as the hero | a series over time | `TideStyle` |
| Quiet (words only) | nothing | `templates/Gallery` |
| Ticket or receipt | nothing | `templates/Gallery` |
| Whole thing on one card, no boxes | nothing | `templates/Gallery` (Memory) |
| One item as hero (a song, a place) | an item with artwork | `templates/Gallery` (Song) |
| Period recap (month, year) | several records | `templates/Gallery` (Month) |
| Thank-you to a person | a named person | `templates/Gallery` (Thank You) |

## Code shape

The goal is that the twentieth style costs one file and one line.

- **`ShareCardContent`**: a `Sendable` struct of plain values built once from the model, in a `.task`, never in a view body. Cards never read the database. Ship three fixtures with it: `sample`, `sparse`, `long`.
- **`ShareCardStyle`** protocol: `id`, `name`, `tagline`, `group`, `kind` (card or sticker), `tier` (free or pro), `backgrounds`, `options(for:)` (at most three), `isAvailable(for:)`, `body(_:)`.
- **`ShareCardRegistry.all`**: the one list the picker and the tests read.
- **`ShareCardRenderer`**: `ImageRenderer` with fixed traits (text size, appearance, layout direction), so the image is the same on every phone. Opaque for cards, alpha for stickers, a proposed width for stickers so long text wraps instead of being cut.
- **Plain fills only inside a card.** `ImageRenderer` draws what SwiftUI rasterises itself; views composited by Core Animation come out as placeholders. No glass or materials in a card.
- **Type by role**: styles call `cardFont(size, weight)`, `cardWords(size)`, `cardClock(size)`; the renderer sets the typeface once through the environment. See `references/typefaces.md`.
- **Options are data** (`toggle` or `choice`), stored per style in one Codable blob. A choice that only makes sense for one record (which quote) is not remembered.
- **Keep it out of widget and Watch targets** if `Shared/` is compiled into them.

`templates/README.md` lists every file and what to rename.

## Fonts

Ten typefaces that ship with iOS are in `ShareCardTypeface`: Tall, Rounded, Plain, Wide, Editorial, Avenir, Futura, Didot, DIN, Mono. None needs a font file. Wide and narrow faces carry scale factors so hero numbers and titles still fit. Mock all the candidates on the same cards (`./render.sh <dir> fonts`) and let the owner pick the standard. `references/typefaces.md` has the table, the fit rules and the device caveat.

## Free and paid

Sharing is how an app gets found, so the cards themselves should be free; a shared card is an advert the person chose to post. Things that are reasonable to charge for: a choice of font, recap cards built from many records, extra looks. Let anyone preview a paid option on their own data before the paywall. Any paid option needs a true line on the paywall, and the store listing must not promise it as free.

## Report honestly

The simulator has no Instagram. Before calling the work done, list what was and was not checked:

- Rendered sizes, alpha and long strings: checked by tests.
- The picker: looked at in the simulator, including the largest text size.
- Add to Story, sticker placement and size, pasted stickers keeping transparency, video backgrounds: need a phone with Instagram.
- Named fonts: resolve in the simulator; confirm on a device.
- Real photos: tests use a white photo and contrast arithmetic.

## References

- `references/design-principles.md`: the rules in depth, with sources. Read first.
- `references/instagram-handoff.md`: pasteboard keys, what goes in which layer, fallbacks, the phone checklist.
- `references/typefaces.md`: the ten faces, roles, fit, Pro gating.
- `references/portable-prompt.md`: a self-contained prompt for tools that do not have this skill.
- `references/sources.md`: every source, with what it supports and when it was checked.
