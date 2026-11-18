import SwiftUI

/// The heart-rate line as the hero. Words by default, numbers by choice.
struct TideStyle: ShareCardStyle {
    let id = "tide"
    var name: String { String(localized: "Tide", comment: "Share card style name") }
    var tagline: String { String(localized: "The shape of your effort, start to savasana.", comment: "Share card style description") }
    let group = ShareCardGroup.classCard
    let backgrounds: [ShareCardBackgroundKind] = [.colour, .dark, .photo]

    func isAvailable(for content: ShareCardContent) -> Bool {
        (content.heart?.curve.count ?? 0) > 2
    }

    func options(for content: ShareCardContent) -> [ShareCardOption] {
        // Beats per minute are off until the person turns them on.
        [.toggle("bpm", String(localized: "Beats per minute", comment: "Share card option: show heart-rate numbers"), default: false)]
    }

    func body(_ context: ShareCardContext) -> AnyView {
        let content = context.content
        guard let heart = content.heart else { return AnyView(EmptyView()) }
        // With no words to show, the numbers are all there is.
        let showNumbers = context.isOn("bpm") || (heart.effortWord == nil && heart.easeWord == nil)
        return AnyView(ShareCardFrame(context: context, scrim: .haze, alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    ShareCardKicker(text: "\(content.kicker) · \(content.dateText)")
                    Spacer(minLength: 8)
                    ShareCardWordmark()
                }
                Text(verbatim: content.title)
                    .cardFont(context.pick(28, 26, 24))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.top, 6)
                Spacer(minLength: 8)
                VStack(spacing: 6) {
                    ShareCardTide(heart: heart, lineWidth: 3)
                        .frame(height: context.pick(190, 132, 96))
                    HStack {
                        Text(verbatim: content.startTimeText)
                        Spacer()
                        if let minutes = content.minutesText { Text(verbatim: minutes) }
                    }
                    .cardClock(10.5)
                    .opacity(0.66)
                    .padding(.horizontal, context.insets.leading)
                }
                // The line runs edge to edge; only its labels keep the margin.
                .padding(.horizontal, -context.insets.leading)
                Spacer(minLength: 8)
                HStack(alignment: .lastTextBaseline, spacing: context.pick(28, 28, 24)) {
                    if showNumbers {
                        metric(String(localized: "Peak", comment: "Share card label: peak heart rate"), "\(heart.peakBPM)", size: context.pick(40, 36, 32))
                        metric(String(localized: "Average", comment: "Share card label: average heart rate"), "\(heart.averageBPM)", size: context.pick(40, 36, 32))
                    } else {
                        if let effort = heart.effortWord {
                            metric(String(localized: "Effort", comment: "Share card label above the effort word"), effort, size: context.pick(34, 31, 28))
                        }
                        if let ease = heart.easeWord {
                            metric(String(localized: "Ease", comment: "Share card label above the ease word"), ease, size: context.pick(34, 31, 28))
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        })
    }

    private func metric(_ label: String, _ value: String, size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: label).cardFont(12, .medium).opacity(0.7)
            Text(verbatim: value).cardFont(size).tracking(-0.5)
        }
        .fixedSize()
    }
}
