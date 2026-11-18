import SwiftUI

/// One large number over the photo. The simplest card there is.
struct OneNumberStyle: ShareCardStyle {
    let id = "one-number"
    var name: String { String(localized: "One Number", comment: "Share card style name") }
    var tagline: String { String(localized: "One big number over your photo.", comment: "Share card style description") }
    let group = ShareCardGroup.simple
    let backgrounds: [ShareCardBackgroundKind] = [.photo, .colour, .dark]

    func isAvailable(for content: ShareCardContent) -> Bool {
        ShareCardNumber.option(for: content) != nil
    }

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        var options = [ShareCardNumber.option(for: content)].compactMap { $0 }
        if content.studio != nil {
            options.append(.toggle("studio", String(localized: "Studio", comment: "Share card option: show the studio name")))
        }
        return options
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        let number = ShareCardNumber.value(context.choice(ShareCardNumber.optionID), in: content)
        let place = [context.isOn("studio") ? content.studio : nil, content.dateText]
            .compactMap { $0 }.joined(separator: " · ")
        return AnyView(ShareCardFrame(context: context) {
            VStack(alignment: .leading, spacing: 0) {
                if let number {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: number.figure)
                            .cardFont(context.pick(176, 150, 128))
                            .tracking(-5)
                        Text(verbatim: number.unit)
                            .cardFont(context.pick(30, 26, 24), .semibold)
                            .opacity(0.86)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.bottom, context.pick(-10, -8, -8))
                }
                Text(verbatim: content.title)
                    .cardFont(context.pick(24, 22, 21), .semibold)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: place)
                        .cardFont(14, .medium)
                        .opacity(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 8)
                    ShareCardWordmark()
                }
                .padding(.top, 5)
            }
        })
    }
}
