import SwiftUI

/// The photo is the card. One thin bar carries the class.
struct CaptionStyle: ShareCardStyle {
    let id = "caption"
    var name: String { String(localized: "Caption", comment: "Share card style name") }
    var tagline: String { String(localized: "Your photo, one thin line of class.", comment: "Share card style description") }
    let group = ShareCardGroup.simple
    let backgrounds: [ShareCardBackgroundKind] = [.photo, .colour]

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        var options: [ShareCardOption] = [
            .choice("bar", String(localized: "Bar", comment: "Share card option: colour of the caption bar"), [
                .init(id: "dark", title: String(localized: "Dark", comment: "Caption bar colour")),
                .init(id: "light", title: String(localized: "Light", comment: "Caption bar colour")),
            ]),
        ]
        if content.studio != nil {
            options.append(.toggle("studio", String(localized: "Studio", comment: "Share card option: show the studio name")))
        }
        return options
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        let light = context.choice("bar") == "light"
        // Studio, else the class style, unless that only repeats the title.
        let second = [context.isOn("studio") ? content.studio : nil, content.kicker]
            .compactMap { $0 }.first { $0 != content.title }
        return AnyView(ShareCardFrame(context: context, scrim: .none, alignment: .bottom) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: content.title).cardFont(15, .semibold)
                    if let second {
                        Text(verbatim: second).cardFont(12, .medium).opacity(0.7)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    if let minutes = content.minutesText {
                        Text(verbatim: minutes).cardFont(15, .semibold)
                    }
                    if let songs = content.songsText {
                        Text(verbatim: songs).cardFont(12, .medium).opacity(0.7)
                    }
                }
                .layoutPriority(1)
            }
            .lineLimit(1)
            .foregroundStyle(light ? ShareCardPalette.ink : .white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                (light ? ShareCardPalette.paper : ShareCardPalette.ink).opacity(0.94),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .padding(.horizontal, -8)
        })
    }
}
