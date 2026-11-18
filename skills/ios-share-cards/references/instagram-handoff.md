# Handing cards to Instagram Stories

From Meta's "Sharing to Stories" page [S9 in `sources.md`], read on 18 Nov 2026, plus what was learned building it. The simulator has no Instagram, so everything on this page that touches Instagram itself must be checked on a phone.

## Setup

- A public Meta App ID (digits only). It is sent as `source_application`; it is not a secret. Never ship the App Secret.
- `instagram-stories` in `LSApplicationQueriesSchemes`, or `canOpenURL` is always false.
- No SDK, no login, no app review.

## The mechanism

1. Put one item on `UIPasteboard.general` with an expiry (Meta's sample uses five minutes).
2. Open `instagram-stories://share?source_application=<App ID>`.

| Pasteboard key | Value | Notes from Meta |
|---|---|---|
| `com.instagram.sharedSticker.backgroundImage` | image data | JPG or PNG, at least 720×1280, 9:16 or 9:18 |
| `com.instagram.sharedSticker.stickerImage` | image data | JPG or PNG, recommended 640×480; shown as a sticker the person can move |
| `com.instagram.sharedSticker.backgroundTopColor` | hex string | with the bottom colour, a solid or gradient behind a sticker |
| `com.instagram.sharedSticker.backgroundBottomColor` | hex string | default background is `#222222` when neither is set |
| `com.instagram.sharedSticker.appID` | the App ID | used by the shipped code alongside the URL parameter |

Meta's rule: pass a background (image or video), a sticker, or both.

## What to send for each kind of card

| Sharing | Background | Sticker | Status |
|---|---|---|---|
| A Story-shaped card | the card, 1080×1920 | none | Shipped |
| A sticker over the person's photo | their photo, cropped to 9:16, as JPEG | the sticker PNG with alpha | Shipped; check size and placement on a phone |
| A sticker with no photo | none; top and bottom colours | the sticker PNG | Shipped; check on a phone |
| A feed-shaped card to a Story | a backdrop | the card with rounded corners | Works, but prefer sending the Story-shaped version |
| A sticker over a video | the video (20 s at most, under 50 MB) | the sticker PNG | Not shipped: the iOS key for video is not named on Meta's page. Try `com.instagram.sharedSticker.backgroundVideo` on a phone first |

Send a photo background as JPEG. The same photo as PNG can be tens of megabytes on the pasteboard.

## Outside Instagram

- **Not installed, or no App ID in the build:** hand the flat 9:16 image to the system share sheet. For a sticker, flatten it onto the photo or colour first.
- **Instagram refuses to open:** say so plainly and offer the share sheet.
- **Copy Sticker:** put the PNG on the pasteboard under `public.png` so the person can paste it onto a Story they shoot in Instagram. Whether the paste keeps transparency is unconfirmed.
- **Sharing a sticker file:** write the PNG to a temporary file and share the URL. A `UIImage` handed to the share sheet may be re-encoded without alpha.
- **Saving to Photos** needs `NSPhotoLibraryAddUsageDescription`. The share sheet's own Save Image avoids adding a permission.
- **Snapchat and TikTok** need their SDKs for a direct hand-off. Without them, they get the flat image through the share sheet.

## Make it testable

Put `canOpenURL`, `open` and the pasteboard behind a small protocol so tests can check, without Instagram:

- the URL is exactly `instagram-stories://share?source_application=<id>`;
- a Story card sends a background and no sticker;
- a sticker over a photo sends both, the background decodes to 1080×1920, the sticker data starts with the PNG signature and has alpha;
- nothing is put on the pasteboard when Instagram is not installed;
- the expiry is set.

`templates/Rendering/InstagramStories.swift` and `StickerStory.swift` are that code.

## Phone checklist

Put this in the pull request and leave unchecked what was not done.

- [ ] Add to Story with a Story-shaped card: fills the frame, nothing under Instagram's header or reply bar
- [ ] A sticker over a photo: arrives movable, at a sensible size, sharp when pinched larger
- [ ] A sticker with no photo: the colour behind it is the chosen one
- [ ] Copy Sticker, shoot in Instagram, paste: transparency kept?
- [ ] Instagram not installed: the share sheet opens with the flat image
- [ ] Every named font appears (see `typefaces.md`)
