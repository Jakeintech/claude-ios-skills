import SwiftUI

/// The playlist from class, in the order it was played.
struct SetlistStyle: ShareCardStyle {
    let id = "setlist"
    var name: String { String(localized: "Setlist", comment: "Share card style name") }
    var tagline: String { String(localized: "Every song, in the order it played.", comment: "Share card style description") }
    let group = ShareCardGroup.classCard
    let backgrounds: [ShareCardBackgroundKind] = [.colour, .photo, .dark]

    func isAvailable(for content: ShareCardContent) -> Bool { !content.songs.isEmpty }

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        var options: [ShareCardOption] = [
            .toggle("times", String(localized: "Times", comment: "Share card option: show when each song played")),
        ]
        if content.teacher != nil {
            options.append(.toggle("teacher", String(localized: "Teacher", comment: "Share card option: show the teacher's name")))
        }
        return options
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        let limit = context.pick(10, 7, 5)
        // Room for the "and N more" line when the list is cut.
        let shown = Array(content.songs.prefix(content.songs.count > limit ? limit - 1 : limit))
        let rest = content.songs.count - shown.count
        let showTimes = context.isOn("times")
        var footer = [content.songsText, content.minutesText].compactMap { $0 }
        if context.isOn("teacher"), let teacher = content.teacher {
            footer.append(String(localized: "with \(teacher)", comment: "Share card: who taught the class"))
        }
        return AnyView(ShareCardFrame(context: context, scrim: .haze, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ShareCardKicker(text: String(localized: "Played in class", comment: "Share card heading above the song list"))
                Text(verbatim: content.title)
                    .cardFont(context.pick(28, 26, 24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 6)
                Spacer(minLength: context.pick(18, 12, 10))
                VStack(alignment: .leading, spacing: context.pick(13, 11.5, 10.5)) {
                    ForEach(shown) { song in
                        HStack(alignment: .firstTextBaseline, spacing: 12) {
                            if showTimes {
                                Text(verbatim: song.clock)
                                    .cardClock(11)
                                    .foregroundStyle(ShareCardPalette.second)
                                    .fixedSize()
                                    .frame(width: 50, alignment: .leading)
                            }
                            // The artist drops out before the title is cut.
                            ViewThatFits(in: .horizontal) {
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text(verbatim: song.title).cardFont(15.5, .semibold)
                                    Text(verbatim: song.artist).cardFont(12.5, .medium).opacity(0.66)
                                }
                                .fixedSize()
                                Text(verbatim: song.title).cardFont(15.5, .semibold)
                            }
                            Spacer(minLength: 0)
                        }
                        .lineLimit(1)
                    }
                    if rest > 0 {
                        Text("and \(rest) more", comment: "Share card: songs that did not fit the list")
                            .cardFont(12.5, .medium)
                            .opacity(0.66)
                            .padding(.leading, showTimes ? 62 : 0)
                    }
                }
                Spacer(minLength: context.pick(18, 12, 10))
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: footer.joined(separator: " · "))
                        .cardFont(12.5, .medium)
                        .opacity(0.8)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Spacer(minLength: 8)
                    ShareCardWordmark()
                }
            }
        })
    }
}
