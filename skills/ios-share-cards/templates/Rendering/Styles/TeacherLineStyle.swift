import SwiftUI

/// One thing the teacher said, set large.
struct TeacherLineStyle: ShareCardStyle {
    let id = "teacher-line"
    var name: String { String(localized: "Teacher's Line", comment: "Share card style name") }
    var tagline: String { String(localized: "One line worth keeping, set large.", comment: "Share card style description") }
    let group = ShareCardGroup.classCard
    let backgrounds: [ShareCardBackgroundKind] = [.colour, .photo, .paper]

    func isAvailable(for content: ShareCardContent) -> Bool { !content.lines.isEmpty }

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        var options: [ShareCardOption] = []
        if content.lines.count > 1 {
            // Which line belongs to this class only, so it is not remembered.
            options.append(.choice(
                "line", String(localized: "Line", comment: "Share card option: which of the teacher's lines"),
                content.lines.indices.map { .init(id: "\($0)", title: content.lines[$0]) },
                persists: false
            ))
        }
        if content.teacher != nil {
            options.append(.toggle("teacher", String(localized: "Teacher's name", comment: "Share card option: show who said the line")))
        }
        return options
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        let index = Int(context.choice("line")) ?? 0
        let line = content.lines.indices.contains(index) ? content.lines[index] : (content.lines.first ?? "")
        let speaker = context.isOn("teacher") ? content.teacher : nil
        return AnyView(ShareCardFrame(context: context, scrim: .haze, alignment: .leading) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)
                Image(systemName: "quote.opening")
                    .font(.system(size: context.pick(26, 24, 22), weight: .bold))
                    .foregroundStyle(ShareCardPalette.accent)
                    .padding(.bottom, context.pick(16, 14, 12))
                // Long lines shrink to fit; they are never cut.
                Text(verbatim: line)
                    .cardWords(context.pick(40, 37, 33))
                    .lineSpacing(1)
                    .minimumScaleFactor(0.4)
                VStack(alignment: .leading, spacing: 3) {
                    if let speaker {
                        Text(verbatim: speaker).cardFont(17, .semibold)
                    }
                    Text(verbatim: [content.kicker, content.studio].compactMap { $0 }.joined(separator: " · "))
                        .cardFont(13, .medium).opacity(0.76)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, context.pick(24, 20, 16))
                Spacer(minLength: 0)
                HStack { Spacer(); ShareCardWordmark(color: context.ink) }
            }
        })
    }
}
