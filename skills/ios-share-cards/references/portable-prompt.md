# Portable prompt: share cards for another app

Paste everything inside the block into a session for another app. Fill in the first section. It is self-contained, so it works in tools that do not have the `ios-share-cards` skill. In Claude Code with the skill installed, add "use the ios-share-cards skill" and the templates come with it.

```text
You are designing and then building social share cards for an iOS app. A share
card is a small poster the person posts for us: seen for about a second, on a
phone, inside another app. Work in two stages. Stage 1 is mock-ups I pick from.
Do not write app code until I have picked.

ABOUT THE APP (fill in)
- App and what it tracks: <e.g. Reps: strength workouts>
- The record being shared: <a workout / a trip / a day / a class>
- What a record has: <duration, counts, an ordered list, a quote or note,
  a series over time, a photo, a person, a place>
- Brand: background colours <...>, one accent <...>, colours to avoid <...>
- Paid tier, if any: <name>, and what is already paid
- Where the current share flow lives, if there is one: <files>

DESIGN RULES
1. One hero per card: one number, one line of words, one list, one chart or
   one photo. Offer many simple styles, not one dense one.
2. Few, large things. At most three numbers. On a 360 pt wide canvas the
   smallest text is 12.5 pt and hero numbers are 130 to 220 pt. Medium weight
   and up; Apple advises against light weights and sets 11 pt as the iOS
   minimum for interface text, and a card is read faster than an interface [2].
3. No boxes. No bordered panels, stat tiles, dividers between numbers or icon
   bullets. The only filled shapes have a job: a caption bar over a photo, a
   sticker pill, a paper ticket.
4. One typeface, four roles: display (numbers, titles), text (labels), words
   (anything a person said: in quotation marks, as a serif italic or a
   medium sans, whichever fits the app's design), clock (times: monospaced).
   Apple: "Minimize the number of typefaces you use" [2]. Use faces that ship
   with iOS: SF Pro in its widths (compressed, condensed, standard, expanded
   [6]), SF Rounded, New York, SF Mono, Avenir Next, Futura, Didot, DIN [8].
   No font files. Wide faces set hero numbers at about 78% size; compressed
   ones at about 128%.
5. The background is the colour: one field of colour or one photo, white or
   ink text. One small accent mark per card. Each accent means one thing.
   Never carry meaning in colour alone [3].
6. Readable over any photo. Text never sits on a raw photo. Use a bottom
   scrim (black 0% to 80%), a haze (blur plus black at 58%), or a solid bar.
   White text must hold 4.5:1 on a pure white photo [1][3]. Prove it with the
   WCAG formula (L1 + 0.05) / (L2 + 0.05) in a test: black at 58% over white
   gives about 5.3:1; 52% gives about 4.3:1 and fails.
7. Three shapes, each laid out on purpose, never cropped: Story 9:16
   (1080×1920), Post 4:5 (1080×1350), Square 1:1 (1080×1080). Meta asks for a
   Story background of at least 720×1280 at 9:16 [9]. In a Story keep the top
   250 px and bottom 340 px free; the host app draws there. Treat those two
   numbers as a working default and check them on a real Story [10].
8. Stickers are transparent, sized by their content, and use only fills and
   soft shadows, because another app does the compositing. Offer a small
   pill, a medium stack of bare type and a wide lower third.
9. The person's own data everywhere: previews, thumbnails, font samples. A
   style that needs something the record lacks is left out, not greyed.
10. Private by default: no street addresses on cards; body numbers and other
    people's names are options that start off or can be turned off. Counts,
    not scores.

STAGE 1: MOCK-UPS
- If a share flow exists, run the app with demo data, screenshot it, and say
  plainly what dates it.
- Propose 10 to 12 styles from very simple to rich, mapped to this app's data:
  one number; photo with a thin caption bar; words only; stickers (pill,
  stack, lower third); an ordered list; one quote set large; one line chart
  as the hero; a ticket or receipt; the whole record on one card with no
  boxes; one item as hero; a month or year recap; a thank-you to a person.
- Render them with real type and real demo data, in all three shapes. On
  Apple platforms render SwiftUI with ImageRenderer rather than drawing
  pictures of an interface. If you need photos and have none, draw stand-ins
  and say they are drawn.
- Show: the family, the three shapes, the same cards over a bright, a dark
  and a busy photo, the stickers placed on a Story, and the picker.
- Mock the candidate typefaces on the same five cards and recommend one.
- Recommend which six styles to build first, with a build order, and which
  parts are free and which belong to the paid tier. Cards themselves should
  be free: a shared card is an advert the person chose to post.

STAGE 2: BUILD (after I pick)
- Content: one Sendable struct of plain values built once from the model,
  never in a view body. Three fixtures: full, nearly empty, very long strings.
- One style protocol (id, name, group, kind card or sticker, tier, supported
  backgrounds, at most three options, isAvailable, body) and one registry the
  picker and the tests read. A new style is one file and one line.
- Render with ImageRenderer at 3× with fixed traits. It only draws what
  SwiftUI rasterises itself, so no glass or materials inside a card [5].
  Give stickers a proposed width and use ViewThatFits so long text wraps and
  the sticker grows instead of being cut [7].
- Type by role through the environment, so no style names a font.
- Picker: a full-height pager of the live card, a strip of live thumbnails in
  groups, one shape control, an options sheet with at most three options per
  style, one main action. Liquid Glass belongs to the picker's controls, not
  the card [4]. Check it at the largest accessibility text size.
- Instagram Stories on iOS [9]: put one item on the pasteboard with a
  five-minute expiry and open
  instagram-stories://share?source_application=<Meta App ID>.
  Keys: com.instagram.sharedSticker.backgroundImage, .stickerImage,
  .backgroundTopColor, .backgroundBottomColor. A Story card is the background
  with no sticker. A sticker goes over the person's photo (sent as JPEG) or
  over two colours. Add instagram-stories to LSApplicationQueriesSchemes.
  Without Instagram, hand the flat image to the system share sheet.
  Do not ship a video background until the pasteboard key is confirmed on a
  phone; Meta documents the feature (20 seconds, under 50 MB) but its page
  does not name the iOS key.
- Tests: every style × shape × typeface × fixture renders at the exact pixel
  size; cards are opaque; stickers have transparent corners and are not cut
  off with long text; every named font resolves; at most three options per
  style; the contrast function holds 4.5:1; the hand-off puts the right layers
  on the pasteboard. One reference image per style and shape.

HOW TO REPORT
- Say what you verified and how, and what you could not. The simulator has no
  Instagram, so Add to Story, sticker size and placement, pasted stickers
  keeping transparency, and named fonts on a real device stay open until
  someone checks on a phone. Put that checklist in the pull request.
- Flag anything that changes paywall or store listing copy.
- Do not merge or upload a build unless I say so.

SOURCES (checked 18 Nov 2026)
[1] W3C, WCAG 2.2 Understanding SC 1.4.3 Contrast (Minimum)
    https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html
[2] Apple HIG, Typography
    https://developer.apple.com/design/human-interface-guidelines/typography
[3] Apple HIG, Accessibility
    https://developer.apple.com/design/human-interface-guidelines/accessibility
[4] Apple HIG, Materials
    https://developer.apple.com/design/human-interface-guidelines/materials
[5] Apple, SwiftUI ImageRenderer
    https://developer.apple.com/documentation/swiftui/imagerenderer
[6] Apple, SwiftUI Font.Width
    https://developer.apple.com/documentation/swiftui/font/width
[7] Apple, SwiftUI ViewThatFits
    https://developer.apple.com/documentation/swiftui/viewthatfits
[8] Apple, System Fonts
    https://developer.apple.com/fonts/system-fonts/
[9] Meta, Sharing to Stories
    https://developers.facebook.com/docs/instagram-platform/sharing-to-stories
[10] Meta Business Help Center, safe zone for ads in Stories and Reels
    https://www.facebook.com/business/help/980593475366490
    (confirms a safe zone exists; the pixel numbers above are a working
    default, not quoted from this page)
Rules 1, 3, 8, 9 and the "few, large" sizes are design judgement from a
redesign the owner approved, not from a published standard.
```
