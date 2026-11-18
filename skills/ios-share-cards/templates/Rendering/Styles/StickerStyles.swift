import SwiftUI

// Transparent overlays for the person's own Story photo or video. Instagram
// places them as a sticker that can be moved, pinched and rotated.

/// Small. Tuck it in a corner.
struct PillSticker: ShareCardStyle {
    let id = "sticker-pill"
    var name: String { String(localized: "Pill", comment: "Share sticker style name") }
    var tagline: String { String(localized: "Small. Tuck it in a corner.", comment: "Share sticker style description") }
    let group = ShareCardGroup.sticker
    let kind = ShareCardKind.sticker
    let backgrounds: [ShareCardBackgroundKind] = []

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        [.choice("look", String(localized: "Look", comment: "Share sticker option: dark or light"), [
            .init(id: "dark", title: String(localized: "Dark", comment: "Sticker colour")),
            .init(id: "light", title: String(localized: "Light", comment: "Sticker colour")),
        ])]
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        let light = context.choice("look") == "light"
        return AnyView(
            HStack(spacing: 9) {
                Circle().fill(ShareCardPalette.accent).frame(width: 7, height: 7)
                Text(verbatim: content.title)
                    .cardFont(15, .semibold)
                    .lineLimit(1)
                    .frame(maxWidth: 220)
                if let minutes = content.minutesText {
                    Text(verbatim: minutes).cardFont(15, .medium).opacity(0.7).fixedSize()
                }
            }
            .foregroundStyle(light ? ShareCardPalette.ink : .white)
            .padding(.horizontal, 17)
            .padding(.vertical, 11)
            .background((light ? ShareCardPalette.paper : ShareCardPalette.ink).opacity(0.94), in: Capsule())
            .padding(10)
        )
    }
}

/// Bare type, no box.
struct StackSticker: ShareCardStyle {
    let id = "sticker-stack"
    var name: String { String(localized: "Stack", comment: "Share sticker style name") }
    var tagline: String { String(localized: "Bare type, no box.", comment: "Share sticker style description") }
    let group = ShareCardGroup.sticker
    let kind = ShareCardKind.sticker
    let backgrounds: [ShareCardBackgroundKind] = []

    func isAvailable(for content: ShareCardContent) -> Bool {
        ShareCardNumber.option(for: content) != nil
    }

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        [ShareCardNumber.option(for: content)].compactMap { $0 }
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        let choice = context.choice(ShareCardNumber.optionID)
        let number = ShareCardNumber.value(choice, in: content)
        // The second line carries whatever the big number does not.
        let detail = [content.studio, choice == "songs" ? content.minutesText : content.songsText]
            .compactMap { $0 }.joined(separator: " · ")
        let stack = VStack(alignment: .leading, spacing: 0) {
            if let number {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(verbatim: number.figure).cardFont(104).tracking(-3)
                    Text(verbatim: number.unit).cardFont(22, .semibold).opacity(0.9)
                }
                .fixedSize()
                .padding(.bottom, -8)
            }
            Text(verbatim: content.title).cardFont(21, .semibold)
            if !detail.isEmpty {
                Text(verbatim: detail)
                    .cardFont(13.5, .medium).opacity(0.88)
                    .padding(.top, 3)
            }
            ShareCardWordmark().padding(.top, 10)
        }
        .lineLimit(2)
        .foregroundStyle(.white)
        .shareCardOverPhotoShadow()
        return AnyView(
            // Its natural size when that fits a Story; otherwise a fixed
            // width so long titles wrap and the sticker grows downwards.
            // (A flexible frame here reports the unwrapped height and the
            // last line gets cut off.)
            ViewThatFits(in: .horizontal) {
                stack.fixedSize()
                stack
                    .frame(width: Self.wrappedWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        )
    }

    static let wrappedWidth: CGFloat = 300
}
