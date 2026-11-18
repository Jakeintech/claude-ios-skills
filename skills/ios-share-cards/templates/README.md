# Templates

Copies of code that shipped in a class-tracking app (classes with songs, a teacher's lines and heart rate). The domain shows in three style names and in the content model; everything else is general. Replace `APPNAME` and the nouns.

## Gallery/ : mock-ups on a Mac, before any app code

Self-contained. Not part of any Xcode target.

```bash
./render.sh /tmp/share-cards          # every style in every shape, plus sheets
./render.sh /tmp/share-cards fonts    # five cards in each of ten typefaces
```

- `GalleryPlates.swift`: the demo record and three drawn stand-in photos (bright, dark, busy). Replace the record with the app's demo data.
- `ShareCardStyles.swift`: twelve styles, including the seven that have no app version below (Quiet, Ticket, Memory, Song, Month, Thank You, Lower Third).
- `GalleryPickerMock.swift`: a drawn picture of the picker. It fakes glass with fills, because `ImageRenderer` cannot draw Liquid Glass.
- Needs macOS 15 and the Xcode toolchain. Compiles with `-swift-version 5`.

## Rendering/ : the kit, compiles as it stands

Typechecked alone with `swiftc -typecheck -target arm64-apple-ios26.0-simulator -swift-version 6 -strict-concurrency=complete`.

| File | What it is | Change |
|---|---|---|
| `ShareCardContent.swift` | The record as plain values, with `sample`, `sparse` and `long` fixtures | Replace the fields with the app's nouns |
| `ShareCardStyle.swift` | Shapes, colour fields, backgrounds, options, the protocol, the registry, the renderer | Colour fields; the registry list |
| `ShareCardKit.swift` | Palette, wordmark, kicker, backdrop and scrims, the line chart, the frame | `ShareCardPalette.accent`, `.second`, `.wordmark` |
| `ShareCardTypeface.swift` | Ten faces, four roles, fit scales, `cardFont` / `cardWords` / `cardClock` | `standard`; which faces are free |
| `Styles/OneNumberStyle.swift`, `CaptionStyle.swift`, `StickerStyles.swift`, `ShareCardNumber.swift` | General | The numbers offered |
| `Styles/SetlistStyle.swift` | An ordered list with times | Rename; the row |
| `Styles/TeacherLineStyle.swift` | One quote, set large | Rename |
| `Styles/TideStyle.swift` | One line chart as the hero, words or numbers | Rename; the labels |
| `InstagramStories.swift` | Pasteboard keys, the URL, a testable opener, full-frame hand-off | Needs `MetaAppID` in Info.plist and `instagram-stories` in `LSApplicationQueriesSchemes` |
| `StickerStory.swift` | A sticker over a photo or colour, flattened; the sticker hand-off | Nothing |

If `Shared/` is compiled into widget or Watch targets, exclude this folder from them.

## Picker/ : the screen, needs the app's own pieces

Not typechecked here. These expect from the app:

- `Theme` with `background`, `surface`, `accent`, `Spacing` (`xs`, `s`, `m`), `Radius` (`control`, `card`, `sheet`) and `captionFont`;
- `UserSettings` (`@Observable`, with `isProUser`, `shareStudioPrefsData: Data?`, `shareCardTypefaceRaw: String?`);
- a per-record photo store (`ClassMemoryBackgroundStore`: `loadImage(for:)`, `savePhoto(_:for:)`, `removePhoto(for:)`);
- `CameraPicker` and `ActivityShareSheet` (thin UIKit wrappers), `PaywallView(reason:)`, and a `primaryButtonStyle()`;
- the model type in `ShareCardContent+Model.swift` (there `WorkoutSession`).

| File | What it is |
|---|---|
| `ShareStudioView.swift` | The screen: pager, caption, strip, actions, hand-off, alerts |
| `ShareStudioModel.swift` | State, what is remembered, render cache keyed by what an image depends on |
| `ShareStyleStrip.swift` | Thumbnails and group names |
| `ShareOptionsSheet.swift` | Per-style options, background, colour, photo, font |
| `ShareCardFontSettingsView.swift` | Try any font on your own record; use it with the paid tier |
| `ShareStudioPrefs.swift` | The remembered choices as one Codable blob |
| `ShareCardContent+Model.swift` | Builds the content from the model, once |

## Tests/ : Swift Testing

Replace `@testable import APPNAME`. `SnapshotSupport.swift` is the reference-image helper (no third-party library); references are read from the source tree, so exclude `__Snapshots__` from the test target's sources.

- `ShareCardTests.swift`: content, registry, options, backgrounds, rendering at exact size, alpha, reference images, and a dump of every style for review (`TEST_RUNNER_SHARE_CARD_DUMP=<dir>`).
- `ShareCardTypefaceTests.swift`: who gets which font, named fonts exist, every face renders, the sticker is not cut off.
- `ShareStudioModelTests.swift`: loading, remembering, photos, exports.

First run records the reference images and fails once on purpose, so a new image is always looked at before it counts.
