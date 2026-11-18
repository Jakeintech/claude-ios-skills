# Sources

Checked on 18 Nov 2026. Each entry says what it supports. Where a number in this skill does not come from a primary source, it says so.

| # | Source | Supports |
|---|---|---|
| S1 | W3C, Understanding WCAG 2.2, SC 1.4.3 Contrast (Minimum). https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html | Text needs "a contrast ratio of at least 4.5:1"; large text (18 pt, or 14 pt bold) needs 3:1; logotypes are exempt; ratio is (L1 + 0.05) / (L2 + 0.05). |
| S2 | Apple, Human Interface Guidelines, Typography. https://developer.apple.com/design/human-interface-guidelines/typography | iOS default 17 pt, minimum 11 pt; "In general, avoid light font weights"; "Minimize the number of typefaces you use"; SF and New York are the system families; SF has several widths including Condensed and Expanded; custom fonts must be legible. |
| S3 | Apple, Human Interface Guidelines, Accessibility (Vision). https://developer.apple.com/design/human-interface-guidelines/accessibility | Contrast table (up to 17 pt: 4.5:1; 18 pt or bold: 3:1); "Convey information with more than color alone"; thin custom fonts should be set larger. |
| S4 | Apple, Human Interface Guidelines, Materials (Liquid Glass). https://developer.apple.com/design/human-interface-guidelines/materials | "Liquid Glass forms a distinct functional layer for controls and navigation elements"; "Don't use Liquid Glass in the content layer"; clear glass over media; "consider adding a dark dimming layer of 35% opacity" over bright content. |
| S5 | Apple, SwiftUI, ImageRenderer. https://developer.apple.com/documentation/swiftui/imagerenderer | Output "only includes views that SwiftUI rasterizes directly using its own drawing primitives"; views composited by Core Animation get a placeholder. iOS 16, macOS 13. |
| S6 | Apple, SwiftUI, Font.Width. https://developer.apple.com/documentation/swiftui/font/width | `compressed`, `condensed`, `standard`, `expanded`. iOS 16. |
| S7 | Apple, SwiftUI, ViewThatFits. https://developer.apple.com/documentation/swiftui/viewthatfits | "selects the first child whose ideal size on the constrained axes fits within the proposed size". iOS 16. |
| S8 | Apple, System Fonts. https://developer.apple.com/fonts/system-fonts/ | The list of fonts preinstalled on each platform. Avenir Next, Futura, Didot, DIN Alternate and DIN Condensed are tagged iOS system fonts. See the caveat below. |
| S9 | Meta, Sharing to Stories. https://developers.facebook.com/docs/instagram-platform/sharing-to-stories | The `instagram-stories://share?source_application=` scheme; pasteboard keys; background image minimum 720×1280, 9:16 or 9:18; sticker recommended 640×480; video up to 20 seconds, under 50 MB recommended; a background, a sticker or both; default background `#222222`. |
| S10 | Meta Business Help Center, About text overlays and the safe zone for ads in Stories and Reels. https://www.facebook.com/business/help/980593475366490 | That Meta defines a safe zone for Stories. The page body could not be read by tool, so the numbers below are not quoted from it. |

## Things that are not from a primary source

- **Story safe area numbers.** This skill keeps the top 250 px and bottom 340 px of a 1080×1920 Story clear (84 pt and 114 pt on the 360 pt canvas). Those numbers come from the app this was first built for. Third-party guides attribute roughly 14% at the top and 20% at the bottom to Meta (S10) and do not agree with each other on the bottom. Treat the numbers as a working default and look at a real Story before changing them.
- **The iOS pasteboard key for a background video.** S9 documents background video but, as read on 18 Nov 2026, does not name the iOS key. Older versions of the page used `com.instagram.sharedSticker.backgroundVideo`. Try it on a phone before shipping video.
- **Pasting a sticker in Instagram.** Guides describe pasting a copied image into a Story as a sticker. None confirms that a transparent PNG keeps its transparency. Test it.
- **Two serif italics.** `IowanOldStyle-Italic` and `BodoniSvtyTwoITCTT-BookIta` resolve with `UIFont(name:size:)` in the iOS 27.3 simulator. S8, as far as it could be read, tags Iowan Old Style as "document support" and lists Bodoni 72 Book Italic under macOS. Confirm both on a device; a missing custom font falls back to the system font.
- **"Looks dated" judgements** (bordered panels, dense stat rows) are design opinion, drawn from one redesign that the owner approved, not from a study.
