import SwiftUI
import UIKit

/// A sticker laid over the person's photo (or a colour field) in a 9:16
/// frame. Used for the preview, and as the flat image for apps that are not
/// Instagram. Instagram itself gets the two layers separately, so the
/// sticker stays movable there.
struct StickerStoryView: View {
    let sticker: UIImage
    let photo: UIImage?
    let field: ShareCardField

    var body: some View {
        let canvas = ShareCardFormat.story.size
        let insets = ShareCardFormat.story.insets
        ZStack(alignment: .bottomLeading) {
            StickerStoryBackground(photo: photo, field: field)
            Image(uiImage: sticker)
                .resizable()
                .interpolation(.high)
                .frame(width: sticker.size.width, height: sticker.size.height)
                // Stickers carry their own margin; sit them on the safe area.
                .padding(.leading, max(0, insets.leading - 14))
                .padding(.bottom, insets.bottom)
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

/// The 9:16 background Instagram gets under a sticker.
struct StickerStoryBackground: View {
    let photo: UIImage?
    let field: ShareCardField

    var body: some View {
        let canvas = ShareCardFormat.story.size
        Group {
            if let photo {
                Color.black.overlay {
                    Image(uiImage: photo).resizable().aspectRatio(contentMode: .fill)
                }
            } else {
                ShareCardFieldView(field: field)
            }
        }
        .frame(width: canvas.width, height: canvas.height)
        .clipped()
    }
}

@MainActor
enum StickerStoryRenderer {
    private static func render<V: View>(_ view: V, scale: CGFloat) -> UIImage? {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark))
        renderer.scale = scale
        renderer.isOpaque = true
        return renderer.uiImage
    }

    /// The sticker on its background, flattened.
    static func composite(sticker: UIImage, photo: UIImage?, field: ShareCardField, scale: CGFloat = ShareCardFormat.renderScale) -> UIImage? {
        render(StickerStoryView(sticker: sticker, photo: photo, field: field), scale: scale)
    }

    /// The photo alone, cropped to 9:16 at 1080×1920.
    static func background(photo: UIImage) -> UIImage? {
        render(StickerStoryBackground(photo: photo, field: .indigo), scale: ShareCardFormat.renderScale)
    }
}

extension InstagramStorySharer {
    /// A transparent sticker over the person's own photo, or over a colour
    /// when they chose none. Instagram lets them move, pinch and rotate it.
    /// On `.instagramUnavailable` or `.notConfigured`, share the flattened
    /// `StickerStoryRenderer.composite` instead.
    func share(sticker: UIImage, over photo: UIImage?, field: ShareCardField) async -> StoryShareOutcome {
        guard let appID, let url = InstagramStories.shareURL(appID: appID) else { return .notConfigured }
        guard opener.canOpenURL(url) else { return .instagramUnavailable }
        guard let stickerPNG = sticker.pngData() else { return .renderFailed }
        var backgroundData: Data?
        if let photo {
            // JPEG: a photo as PNG can be tens of megabytes on the pasteboard.
            guard let data = StickerStoryRenderer.background(photo: photo)?.jpegData(compressionQuality: 0.9) else {
                return .renderFailed
            }
            backgroundData = data
        }
        let item = InstagramStories.pasteboardItem(
            appID: appID,
            backgroundPNG: backgroundData,
            stickerPNG: stickerPNG,
            topColorHex: field.storyHex.top,
            bottomColorHex: field.storyHex.bottom
        )
        opener.setPasteboardItems([item], expiresIn: InstagramStories.pasteboardLifetime)
        return await opener.open(url) ? .openedInstagram : .openFailed
    }
}
