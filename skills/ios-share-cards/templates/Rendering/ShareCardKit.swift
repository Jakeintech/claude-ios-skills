import SwiftUI
import UIKit

// The pieces share card styles are built from. Everything here draws with
// plain fills: no glass and no materials, which ImageRenderer cannot be
// trusted with and a transparent sticker cannot use.
//
// Type comes from the card's typeface: see `ShareCardTypeface` and the
// `cardFont`, `cardWords` and `cardClock` modifiers.

enum ShareCardPalette {
    static let ink = Color(hex: 0x17141F)
    static let paper = Color(hex: 0xF3EEE6)
    /// The one warm accent a card may use, once, as a small mark. Replace
    /// with the app's own accent.
    static let accent = Color(hex: 0xE8A435)
    /// A second accent with one meaning (here: times in a list).
    static let second = Color(hex: 0xFFB340)
    /// Text on the accent: never white on a light accent.
    static let onAccent = Color(hex: 0x1B1408)
    /// The app's wordmark, set small on every card.
    static let wordmark = "APPNAME"

    /// Black laid over a hazed photo. 0.58 keeps white text above 4.5:1 on a
    /// pure white photo; see `contrastOfWhite(onWhiteUnder:)`.
    static let hazeOpacity = 0.58

    /// WCAG contrast of white text on a white photo under black at `opacity`.
    static func contrastOfWhite(onWhiteUnder opacity: Double) -> Double {
        let channel = 1 - opacity
        let linear = channel <= 0.04045 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        return 1.05 / (linear + 0.05)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

struct ShareCardWordmark: View {
    var color: Color = .white

    var body: some View {
        // The wordmark is a logo: it keeps its own face whatever the typeface.
        Text(verbatim: ShareCardPalette.wordmark)
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(3.2)
            .foregroundStyle(color.opacity(0.72))
    }
}

struct ShareCardKicker: View {
    let text: String
    var color: Color = .white

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(ShareCardPalette.accent).frame(width: 6, height: 6)
            Text(text.uppercased())
                .cardFont(10.5, .bold)
                .tracking(2.2)
                .foregroundStyle(color.opacity(0.72))
                .lineLimit(1)
        }
    }
}

/// One continuous colour field, darker towards the bottom so white text holds.
struct ShareCardFieldView: View {
    let field: ShareCardField

    var body: some View {
        let c = field.colors
        MeshGradient(
            width: 3, height: 4,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.34], [0.62, 0.28], [1, 0.38],
                [0, 0.7], [0.38, 0.66], [1, 0.72],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                c.primary, c.primary, c.tertiary,
                c.secondary, c.primary, c.tertiary,
                c.secondary.mix(with: c.deep, by: 0.35), c.secondary.mix(with: c.deep, by: 0.2), c.primary.mix(with: c.deep, by: 0.45),
                c.deep, c.deep.mix(with: c.secondary, by: 0.25), c.deep,
            ]
        )
    }
}

/// How a photo is darkened under the text.
enum ShareCardScrim {
    /// The photo untouched: the card brings its own solid bar.
    case none
    /// Darkens the lower part, for text set at the bottom.
    case bottom
    /// Blurs and dims the whole photo, for cards with text all over.
    case haze
}

/// The card's background. A photo always gets a scrim under the text, so
/// white type stays readable on any photo.
struct ShareCardBackdrop: View {
    let context: ShareCardContext
    var scrim: ShareCardScrim = .bottom

    var body: some View {
        switch context.background {
        case .field(let field):
            ShareCardFieldView(field: field)
        case .photo(let image):
            Color.black
                .overlay {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .blur(radius: scrim == .haze ? 14 : 0)
                }
                .clipped()
                .overlay { scrimView }
        case .ink:
            ShareCardPalette.ink
        case .paper:
            ShareCardPalette.paper
        case .clear:
            Color.clear
        }
    }

    @ViewBuilder private var scrimView: some View {
        switch scrim {
        case .none:
            EmptyView()
        case .bottom:
            LinearGradient(stops: [
                .init(color: .black.opacity(0.0), location: 0.30),
                .init(color: .black.opacity(0.55), location: 0.62),
                .init(color: .black.opacity(0.80), location: 1.0),
            ], startPoint: .top, endPoint: .bottom)
        case .haze:
            Color.black.opacity(ShareCardPalette.hazeOpacity)
        }
    }
}

/// Lays a card out inside the format's safe area on top of its backdrop.
struct ShareCardFrame<Content: View>: View {
    let context: ShareCardContext
    var scrim: ShareCardScrim = .bottom
    var alignment: Alignment = .bottomLeading
    @ViewBuilder var content: Content

    var body: some View {
        content
            .foregroundStyle(context.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(context.insets)
            .frame(width: context.size.width, height: context.size.height)
            .background { ShareCardBackdrop(context: context, scrim: scrim) }
            .clipped()
    }
}

/// The heart-rate curve as a smooth line.
struct ShareCardTideShape: Shape {
    let values: [Double]
    var closed = false

    func path(in rect: CGRect) -> Path {
        guard values.count > 2 else { return Path() }
        let points: [CGPoint] = values.enumerated().map { index, value in
            CGPoint(
                x: rect.minX + rect.width * CGFloat(index) / CGFloat(values.count - 1),
                y: rect.maxY - rect.height * CGFloat(value)
            )
        }
        var path = Path()
        path.move(to: points[0])
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)], p1 = points[i], p2 = points[i + 1], p3 = points[min(i + 2, points.count - 1)]
            path.addCurve(
                to: p2,
                control1: CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6),
                control2: CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            )
        }
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// The line, a soft fill under it and one marked peak.
struct ShareCardTide: View {
    let heart: ShareCardContent.Heart
    var color: Color = .white
    var lineWidth: CGFloat = 2.5
    var fill = true

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                if fill {
                    ShareCardTideShape(values: heart.curve, closed: true)
                        .fill(LinearGradient(colors: [color.opacity(0.30), color.opacity(0)], startPoint: .top, endPoint: .bottom))
                }
                ShareCardTideShape(values: heart.curve)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                if heart.curve.count > 2 {
                    let index = heart.peakIndex
                    Circle()
                        .fill(ShareCardPalette.accent)
                        .frame(width: lineWidth * 3.6, height: lineWidth * 3.6)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .position(
                            x: geo.size.width * CGFloat(index) / CGFloat(heart.curve.count - 1),
                            y: geo.size.height * (1 - CGFloat(heart.curve[index]))
                        )
                }
            }
        }
    }
}

extension View {
    /// Keeps bare type readable on a photo. For stickers, which cannot bring
    /// their own scrim.
    func shareCardOverPhotoShadow() -> some View {
        shadow(color: .black.opacity(0.55), radius: 1, y: 0.5)
            .shadow(color: .black.opacity(0.35), radius: 9, y: 2)
    }
}
