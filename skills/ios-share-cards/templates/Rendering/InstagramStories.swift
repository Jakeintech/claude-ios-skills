import Foundation
import UIKit

/// Instagram "Sharing to Stories" for iOS, per Meta's documented URL-scheme
/// flow: put the layers on the pasteboard under `com.instagram.sharedSticker.*`
/// keys, then open `instagram-stories://share?source_application=<App ID>`.
/// Needs `instagram-stories` in `LSApplicationQueriesSchemes` and a public
/// Meta App ID (`MetaAppID` in Info.plist). No login, SDK or app review.
enum InstagramStories {
    static let scheme = "instagram-stories"

    enum PasteboardKey {
        static let appID = "com.instagram.sharedSticker.appID"
        static let backgroundImage = "com.instagram.sharedSticker.backgroundImage"
        static let stickerImage = "com.instagram.sharedSticker.stickerImage"
        static let backgroundTopColor = "com.instagram.sharedSticker.backgroundTopColor"
        static let backgroundBottomColor = "com.instagram.sharedSticker.backgroundBottomColor"
    }

    /// Meta's sample expires the items after five minutes so the images
    /// don't linger on the person's clipboard.
    static let pasteboardLifetime: TimeInterval = 5 * 60

    /// A Meta App ID is all digits. Anything else (empty, or an unexpanded
    /// `$(META_APP_ID)` build variable) means the build isn't configured.
    static func validAppID(_ raw: String?) -> String? {
        guard let id = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              (5...20).contains(id.count),
              id.allSatisfy(\.isASCIIDigit) else { return nil }
        return id
    }

    /// The App ID baked into this build, if any.
    static var bundledAppID: String? {
        validAppID(Bundle.main.object(forInfoDictionaryKey: "MetaAppID") as? String)
    }

    static func shareURL(appID: String) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "share"
        components.queryItems = [URLQueryItem(name: "source_application", value: appID)]
        return components.url
    }

    /// The single pasteboard item Instagram reads.
    static func pasteboardItem(
        appID: String,
        backgroundPNG: Data?,
        stickerPNG: Data?,
        topColorHex: String,
        bottomColorHex: String
    ) -> [String: Any] {
        var item: [String: Any] = [
            PasteboardKey.appID: appID,
            PasteboardKey.backgroundTopColor: topColorHex,
            PasteboardKey.backgroundBottomColor: bottomColorHex,
        ]
        if let backgroundPNG { item[PasteboardKey.backgroundImage] = backgroundPNG }
        if let stickerPNG { item[PasteboardKey.stickerImage] = stickerPNG }
        return item
    }
}

private extension Character {
    var isASCIIDigit: Bool { isASCII && isNumber }
}

/// What happened when the person tapped "Instagram Story".
enum StoryShareOutcome: Equatable, Sendable {
    /// Instagram opened its story composer with the card.
    case openedInstagram
    /// Instagram isn't on this phone: offer the system share sheet instead.
    case instagramUnavailable
    /// This build has no Meta App ID: same fallback, and a log for us.
    case notConfigured
    /// Instagram is installed but refused to open.
    case openFailed
    /// The images couldn't be encoded.
    case renderFailed
}

/// Abstracts UIKit so the hand-off can be tested without Instagram.
@MainActor
protocol StoryURLOpening {
    func canOpenURL(_ url: URL) -> Bool
    func open(_ url: URL) async -> Bool
    func setPasteboardItems(_ items: [[String: Any]], expiresIn: TimeInterval)
}

@MainActor
struct SystemStoryURLOpener: StoryURLOpening {
    func canOpenURL(_ url: URL) -> Bool { UIApplication.shared.canOpenURL(url) }
    func open(_ url: URL) async -> Bool { await UIApplication.shared.open(url) }
    func setPasteboardItems(_ items: [[String: Any]], expiresIn: TimeInterval) {
        UIPasteboard.general.setItems(
            items,
            options: [.expirationDate: Date().addingTimeInterval(expiresIn)]
        )
    }
}

@MainActor
struct InstagramStorySharer {
    var appID: String? = InstagramStories.bundledAppID
    var opener: any StoryURLOpening = SystemStoryURLOpener()

    /// Whether the Instagram button should promise a direct hand-off.
    var canShareDirectly: Bool {
        guard let appID, let url = InstagramStories.shareURL(appID: appID) else { return false }
        return opener.canOpenURL(url)
    }

    /// Share one finished full-frame 9:16 image (for example a Year in
    /// Practice frame) as the story background, with no sticker layer.
    /// On `.instagramUnavailable` or `.notConfigured`, present the same
    /// image in the system share sheet instead.
    func share(
        fullFrame image: UIImage,
        topColorHex: String,
        bottomColorHex: String
    ) async -> StoryShareOutcome {
        guard let appID, let url = InstagramStories.shareURL(appID: appID) else {
            return .notConfigured
        }
        guard opener.canOpenURL(url) else { return .instagramUnavailable }
        guard let background = image.pngData() else { return .renderFailed }

        let item = InstagramStories.pasteboardItem(
            appID: appID,
            backgroundPNG: background,
            stickerPNG: nil,
            topColorHex: topColorHex,
            bottomColorHex: bottomColorHex
        )
        opener.setPasteboardItems([item], expiresIn: InstagramStories.pasteboardLifetime)
        return await opener.open(url) ? .openedInstagram : .openFailed
    }
}
