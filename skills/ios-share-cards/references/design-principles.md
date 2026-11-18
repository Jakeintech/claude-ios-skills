# Share card design principles

The rules behind the cards, with the reason for each. Sources are in `sources.md` and cited as [S1] to [S10]. Where a rule is judgement, it says so.

## Contents

1. The situation a card is read in
2. Composition
3. Type
4. Colour and backgrounds
5. Legibility over photos
6. Shapes and safe areas
7. Stickers
8. Data and privacy
9. The picker
10. What makes a card look dated

## 1. The situation a card is read in

A share card is seen once, briefly, on a phone, inside someone else's app. In a Story the host draws a progress bar and avatar over the top and a reply field over the bottom. In a feed the card is one tile among many. The reader did not ask for it and owes it nothing.

That gives four tests for every card:

- **One second.** Can someone say what it is about after one second?
- **Arm's length.** Is every word readable on a phone held normally?
- **Any background.** Does it still read over a bright window, a dark room and a busy sky?
- **Would they post it?** People post things that make them look good. A dense report does not.

## 2. Composition

**One hero per card.** One number, one line of words, one list, one chart, or one photo. Everything else is a caption to the hero. When a card has two heroes, make two styles.

**At most three numbers.** The eye can hold a few. If the screen the card comes from has ten stats, the card picks one and lets the person choose which (an option), rather than showing ten.

**Large, then small, with little in between.** On a 360 pt canvas (rendered at 3× to 1080 px):

| Role | Size |
|---|---|
| Hero number | 130 to 220 pt, depending on the face's width |
| Hero words (a quote) | 33 to 40 pt, shrinking to fit long lines, never cut |
| Title | 21 to 28 pt |
| Labels | 12 to 15.5 pt |
| Smallest text | 12.5 pt (about 37 px in a 1080 px Story) |
| Wordmark | 9 pt, tracked wide |

Apple's minimum for iOS interface text is 11 pt and it advises against light weights [S2]. A card is read faster and further away than an interface, so the floor here is higher and weights are Medium and up.

**No boxes.** Text sits on the background. Bordered panels, stat tiles, dividers between numbers and icon bullets are how a settings screen is built; on a card they read as a screenshot. The exceptions have a job: a caption bar that makes text readable over an untouched photo, a sticker pill, a paper ticket that is the whole idea of the card.

**Leave room.** Cards may be half empty. The empty part is what makes the hero look deliberate.

**One wordmark, small.** The app's name appears once, small, in the same place. It is not a watermark and nobody pays to remove it. Logos are exempt from contrast minimums [S1], but keep it readable anyway.

## 3. Type

**One typeface, four roles.**

- *Display*: hero numbers and titles.
- *Text*: labels and captions.
- *Words*: something a person said. Set it apart so speech reads as speech: quotation marks at least, and either a serif italic or a medium sans, whichever belongs to the app's design. The first app this shipped in began with a serif italic and ended, with its redesign, on a medium sans in quotation marks.
- *Clock*: times and durations in a list, monospaced so digits line up.

Apple's guidance is to "minimize the number of typefaces you use" [S2]. Four roles from one or two families keeps a card coherent while still telling numbers from speech.

**Use faces that ship with iOS.** San Francisco comes in several widths (Condensed and Expanded in Apple's words [S2]; `Font.Width` also offers `compressed` [S6]), plus the Rounded, Serif (New York) and Monospaced designs. Avenir Next, Futura, Didot and DIN are on the system font list [S8]. No font files, no licences, nothing to download.

**Wide faces get smaller; narrow faces get taller.** A hero number in an expanded face needs about 78% of the size to fit the same card; a compressed face can go to about 128%. Carry these as per-face scale factors, not as tweaks in each style.

**Text must survive the worst case.** Titles shrink before they wrap past two lines; a quote shrinks to fit rather than being cut; in a list the secondary text drops out before the primary text truncates. Test with a deliberately long record.

**Fixed traits.** A rendered card ignores Dynamic Type, appearance and bold-text settings, on purpose: the image must be the same on every phone. The picker around it is ordinary UI and does follow Dynamic Type [S2, S3].

## 4. Colour and backgrounds

**The background is the colour.** A card is one field of colour (or one photo) with white or ink text on it. Accents are one small mark per card: a dot before a kicker, the peak on a chart, an opening quote mark.

**Take the colour from the thing itself** where the app has one (a class's mood, a team, a place), so two different records give two different cards. Offer dark and paper (off-white with ink text) as plain alternatives.

**Keep the dark end at the bottom** of a colour field, where text usually sits. Mid-tone fields need checking against white text: 4.5:1 for small text, 3:1 for large or bold [S1, S3].

**Do not carry meaning in colour alone** [S3]. A chart's peak gets a mark and a label, not just a hue.

**Each accent means one thing.** If amber marks times in a list, it marks nothing else.

## 5. Legibility over photos

A person's photo can be anything: a white wall, candlelight, a sunset. Text must not depend on which.

Three treatments, chosen per style:

| Treatment | Use for | How |
|---|---|---|
| Bottom scrim | Text set low over a photo that should stay visible | Black gradient from 0% at 30% height to 55% at 62% and 80% at the bottom |
| Haze | Cards with text all over | Blur the photo (radius about 14 pt on a 360 pt canvas) and lay black at 58% over it |
| Solid bar | The photo must stay untouched | A filled, rounded bar at 94% opacity carrying the text |

**The arithmetic.** WCAG contrast is (L1 + 0.05) / (L2 + 0.05), with L the relative luminance [S1]. Worst case is white text on a pure white photo. Under black at opacity *a*, the white becomes a grey of channel value 1 − *a*. At *a* = 0.58 the grey's luminance is about 0.147, giving 1.05 / 0.197 ≈ 5.3:1, above the 4.5:1 that small text needs [S1, S3]. At 0.52 it falls to about 4.3:1, which fails. Keep the function in code and assert it in a test, so nobody lowers the number by eye.

**Controls over a photo in the picker** (an "Add Photo" button on the preview) are a different matter from text in the card: those are interface, so they use clear Liquid Glass, with a dimming layer if the photo is bright [S4].

## 6. Shapes and safe areas

| Shape | Canvas (pt) | Pixels at 3× | For |
|---|---|---|---|
| Story | 360 × 640 | 1080 × 1920 | Instagram, Facebook and WhatsApp stories |
| Post | 360 × 450 | 1080 × 1350 | Feed, portrait |
| Square | 360 × 360 | 1080 × 1080 | Feed, messages |

Meta's documentation asks for a Story background of at least 720×1280 at 9:16 or 9:18 [S9]; 1080×1920 is comfortably above it.

**Story safe area.** Keep the top 84 pt and bottom 114 pt of the Story canvas free of anything that matters (250 px and 340 px of 1920). The host draws over those bands. The numbers are a working default, not a quoted specification: see `sources.md`.

**Design each shape; do not crop.** A style lays itself out three times. A list shows ten rows in a Story, seven in a Post, five in a Square, and says "and 4 more". A chart gets shorter. A layout may go side by side in the Square.

**Fill the frame.** A Story-shaped card is the whole Story, edge to edge. A small card floating on a backdrop is the older pattern and wastes most of the screen.

## 7. Stickers

A sticker is a transparent image the host app places over the person's own photo or video. They can move, pinch and rotate it [S9].

- **Sized by content**, with a margin of its own, never the full canvas.
- **Fills and soft shadows only.** A sticker cannot blur or tint what is behind it, because the compositing happens in another app. A "glass" pill is a solid at about 94% opacity.
- **Bare type needs two shadows**: a tight dark one for edges and a wide soft one for separation.
- **Offer sizes**: a small pill for a corner, a medium stack of bare type, a wide lower third.
- **Long text wraps and the sticker grows downwards.** Give the renderer a proposed width and use `ViewThatFits` (natural size first, fixed width second) [S7]; a flexible frame reports the unwrapped height and cuts off the last line.

## 8. Data and privacy

- **Real data only.** No sample numbers in a card the person will post. Fixtures are for tests, mock-ups and an explicit "example" label when the person has no records yet.
- **Location detail off by default.** A studio or venue name is fine as an option; a street address is not on a card at all.
- **Body numbers off by default.** Heart rate, weight and similar show as words or shapes first; the figure is an option the person turns on.
- **Other people.** A card that names someone (a teacher, a friend) lets that be turned off.
- **Counts, not scores.** "75 minutes" and "10 songs", not grades, ranks or streak pressure.
- **A style hides when it has nothing to draw.** No empty charts, no "0 of 0".

## 9. The picker

- **The preview is the screen.** A full-height pager of the card with the person's data. Neighbours peek at the edges so it reads as something to swipe.
- **A strip of live thumbnails**, grouped (Simple, Stickers, the app's own group, Recap). Tapping a group jumps to it.
- **One shape control.** Stickers have no shape, so it reads "Sticker" then.
- **At most three options per style**, in a small sheet, plus background and photo. No wall of toggles, and never a toggle that does nothing for the current style.
- **One main action.** "Add to Story" when the card is Story-shaped or a sticker; "Share" for feed shapes. Secondary actions are round buttons.
- **Remember** the last style, shape, colour and per-style options; do not remember choices that belong to one record.
- **Glass belongs to the picker's controls, not the card** [S4].
- **Render outside the view body**, cache by what the image depends on, show a placeholder for the first frame.
- **Check it at the largest text size.** Cap the growth of controls that sit on the card or in the bottom bar, give them a large-content label, and let rows stack.

## 10. What makes a card look dated

Judgement, from one redesign the owner approved. Any two of these and the card reads as old:

- A bordered, rounded panel floating on a backdrop instead of filling the frame.
- A row of three stat cells with dividers.
- Section headings in tiny tracked capitals with an icon each.
- Placeholder tiles (a generic glyph where artwork would be).
- A quote in a tinted box.
- Four accent colours on one card.
- A ring chart with a legend table.
- A picker where the controls take more room than the preview.
- The same accent leading every card regardless of content.
