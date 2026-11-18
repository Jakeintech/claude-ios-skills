// Share card prototype: model, registry and shared drawing pieces.
//
// This folder is a design prototype, not app code. It is not part of any
// Xcode target. It renders the proposed share card styles with SwiftUI's
// ImageRenderer on macOS so the gallery shows real type and colour.
// Build: ./render.sh

import SwiftUI

// MARK: - Content (one snapshot of a class, built once, off the view body)

struct ShareCardContent: Sendable {
    struct Song: Sendable, Identifiable {
        let id: Int
        let title: String
        let artist: String
        let offset: TimeInterval
        var clock: String {
            let total = Int(offset)
            let h = total / 3600, m = (total % 3600) / 60, s = total % 60
            return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
        }
    }

    struct Line: Sendable {
        let text: String
        let speaker: String?
    }

    /// Heart rate from Apple Watch, reduced to what a card needs.
    struct Heart: Sendable {
        /// 0...1, evenly spaced over the class.
        let curve: [Double]
        let peakBPM: Int
        let averageBPM: Int
        let effortWord: String
        let easeWord: String
        var peakIndex: Int { curve.indices.max { curve[$0] < curve[$1] } ?? 0 }
    }

    struct Month: Sendable {
        let name: String
        let year: Int
        let dayCount: Int
        /// 0 = the month starts on a Monday.
        let leadingBlanks: Int
        let classDays: Set<Int>
        let classes: Int
        let minutes: Int
        let songs: Int
        let studios: Int
        let topTeacher: String?
        var hoursText: String { minutes % 60 == 0 ? "\(minutes / 60)h" : "\(minutes / 60)h \(minutes % 60)" }
    }

    struct TeacherTally: Sendable {
        let classes: Int
        let songs: Int
    }

    var title: String
    var style: String
    var dateText: String
    var shortDateText: String
    var timeText: String
    var minutes: Int
    var classNumber: Int
    var teacher: String?
    var studio: String?
    var city: String?
    var songs: [Song]
    var line: Line?
    var heart: Heart?
    var month: Month?
    var withTeacher: TeacherTally?
    var mood: MoodBlend

    var placeLine: String { [studio, shortDateText].compactMap { $0 }.joined(separator: " · ") }
}

// MARK: - Format

enum ShareCardFormat: String, CaseIterable, Sendable {
    case story, portrait, square

    /// Designed in points at 360 wide, rendered at 3x: 1080 px across.
    var size: CGSize {
        switch self {
        case .story: CGSize(width: 360, height: 640)
        case .portrait: CGSize(width: 360, height: 450)
        case .square: CGSize(width: 360, height: 360)
        }
    }

    /// Story: clear of Instagram's own header and reply bar.
    var insets: EdgeInsets {
        switch self {
        case .story: EdgeInsets(top: 84, leading: 26, bottom: 114, trailing: 26)
        case .portrait: EdgeInsets(top: 26, leading: 26, bottom: 26, trailing: 26)
        case .square: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        }
    }

    var label: String {
        switch self {
        case .story: "Story 9:16"
        case .portrait: "Post 4:5"
        case .square: "Square 1:1"
        }
    }
}

// MARK: - Background

struct MoodBlend: Sendable, Equatable {
    let name: String
    let primary: Color
    let secondary: Color
    let tertiary: Color
    let deep: Color

    static let stillHeart = MoodBlend(
        name: "Stillness · Heart",
        primary: Color(hex: 0x5A49B8), secondary: Color(hex: 0x8A3A86), tertiary: Color(hex: 0x3A4FB0),
        deep: Color(hex: 0x1B1638))
    static let flowBreath = MoodBlend(
        name: "Flow · Breath",
        primary: Color(hex: 0x187C7A), secondary: Color(hex: 0x3373BE), tertiary: Color(hex: 0x5A49B8),
        deep: Color(hex: 0x0D2433))
    static let heartGround = MoodBlend(
        name: "Heart · Grounding",
        primary: Color(hex: 0xB03F76), secondary: Color(hex: 0x8A3D4C), tertiary: Color(hex: 0x5A49B8),
        deep: Color(hex: 0x2A1026))
}

enum ShareCardBackground {
    case classColour
    case photo(CGImage)
    case ink
    case paper
    case clear

    var isPhoto: Bool { if case .photo = self { true } else { false } }
    var isLight: Bool { if case .paper = self { true } else { false } }
}

struct ShareCardContext {
    let content: ShareCardContent
    let format: ShareCardFormat
    let background: ShareCardBackground

    var size: CGSize { format.size }
    var insets: EdgeInsets { format.insets }
    /// Text colour for this background.
    var ink: Color { background.isLight ? Palette.ink : .white }
    func pick<T>(_ story: T, _ portrait: T, _ square: T) -> T {
        switch format {
        case .story: story
        case .portrait: portrait
        case .square: square
        }
    }
}

// MARK: - Style protocol and registry

enum ShareCardGroup: String, CaseIterable { case simple = "Simple", sticker = "Stickers", classCard = "Class", recap = "Recap" }
enum ShareCardTier { case free, pro }
enum ShareCardKind { case card, sticker }

@MainActor
protocol ShareCardStyle {
    var id: String { get }
    var name: String { get }
    var tagline: String { get }
    var symbol: String { get }
    var group: ShareCardGroup { get }
    var tier: ShareCardTier { get }
    var kind: ShareCardKind { get }
    /// The first entry is the default.
    var backgrounds: [String] { get }
    /// At most three per style.
    var options: [String] { get }
    func isAvailable(for content: ShareCardContent) -> Bool
    func body(_ ctx: ShareCardContext) -> AnyView
}

extension ShareCardStyle {
    var tier: ShareCardTier { .free }
    var kind: ShareCardKind { .card }
    func isAvailable(for content: ShareCardContent) -> Bool { true }
}

@MainActor
enum ShareCardRegistry {
    /// Adding a style: one file, one line here. The picker and the tests
    /// both read this list.
    static let all: [any ShareCardStyle] = [
        OneNumberStyle(), QuietStyle(), CaptionStyle(),
        PillSticker(), StackSticker(), LowerThirdSticker(),
        SetlistStyle(), TeacherLineStyle(), TideStyle(), TicketStyle(), MemoryStyle(), SongStyle(),
        MonthStyle(), ThanksStyle(),
    ]
}

// MARK: - Palette and type

enum Palette {
    static let ink = Color(hex: 0x17141F)
    static let paper = Color(hex: 0xF3EEE6)
    static let saffron = Color(hex: 0xE8A435)
    static let music = Color(hex: 0xFFC470)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255, blue: Double(hex & 0xFF) / 255)
    }
}

extension Font {
    /// Titles, numbers and small text. The current typeface decides which
    /// face each size gets.
    static func round(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        let face = Typeface.current
        if size >= 60 { return face.display(size * face.numeralScale, weight) }
        if size >= 20 { return face.display(size * face.titleScale, weight) }
        return face.text(size * face.textScale, weight)
    }
    /// The teacher's own words.
    static func words(_ size: CGFloat) -> Font {
        Typeface.current.words(size * Typeface.current.wordsScale)
    }
    static func clock(_ size: CGFloat, _ weight: Font.Weight = .medium) -> Font {
        Typeface.current.clock(size, weight)
    }
}

// MARK: - Shared pieces

struct Wordmark: View {
    var color: Color = .white
    var body: some View {
        Text(verbatim: "APPNAME")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .tracking(3.2)
            .foregroundStyle(color.opacity(0.72))
    }
}

struct Kicker: View {
    let text: String
    var color: Color = .white
    var dot: Bool = false
    var body: some View {
        HStack(spacing: 7) {
            if dot { Circle().fill(Palette.saffron).frame(width: 6, height: 6) }
            Text(text.uppercased())
                .font(.round(10.5, .bold))
                .tracking(2.2)
                .foregroundStyle(color.opacity(0.72))
        }
    }
}

/// One continuous colour field for the class. Stand-in for the redesign's
/// `ClassColour`: same idea, three moods at most, darker towards the bottom
/// so white text holds.
struct MoodField: View {
    let blend: MoodBlend
    var body: some View {
        MeshGradient(
            width: 3, height: 4,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.34], [0.62, 0.28], [1, 0.38],
                [0, 0.7], [0.38, 0.66], [1, 0.72],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                blend.primary, blend.primary, blend.tertiary,
                blend.secondary, blend.primary, blend.tertiary,
                blend.secondary.mix(with: blend.deep, by: 0.35), blend.secondary.mix(with: blend.deep, by: 0.2), blend.primary.mix(with: blend.deep, by: 0.45),
                blend.deep, blend.deep.mix(with: blend.secondary, by: 0.25), blend.deep,
            ]
        )
    }
}

enum Scrim { case none, bottom, top, haze }

/// The card's background. A photo always gets a scrim under the text, so
/// white type stays above 4.5:1 even on a white wall.
struct Backdrop: View {
    let ctx: ShareCardContext
    var scrim: Scrim = .bottom

    var body: some View {
        switch ctx.background {
        case .classColour:
            MoodField(blend: ctx.content.mood)
        case .photo(let image):
            Color.black
                .overlay {
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        // Haze: the photo becomes atmosphere behind a full card.
                        .blur(radius: scrim == .haze ? 14 : 0)
                }
                .clipped()
                .overlay { scrimView }
        case .ink:
            Palette.ink
        case .paper:
            Palette.paper
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
        case .top:
            LinearGradient(stops: [
                .init(color: .black.opacity(0.78), location: 0.0),
                .init(color: .black.opacity(0.5), location: 0.45),
                .init(color: .black.opacity(0.0), location: 0.8),
            ], startPoint: .top, endPoint: .bottom)
        case .haze:
            // 0.58 keeps white text above 4.5:1 on a pure white photo.
            Color.black.opacity(0.58)
        }
    }
}

/// The heart-rate curve as a smooth line.
struct TideShape: Shape {
    let values: [Double]
    var closed = false

    func path(in rect: CGRect) -> Path {
        guard values.count > 2 else { return Path() }
        let pts: [CGPoint] = values.enumerated().map { i, v in
            CGPoint(x: rect.minX + rect.width * CGFloat(i) / CGFloat(values.count - 1),
                    y: rect.maxY - rect.height * CGFloat(v))
        }
        var path = Path()
        path.move(to: pts[0])
        for i in 0..<(pts.count - 1) {
            let p0 = pts[max(i - 1, 0)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[min(i + 2, pts.count - 1)]
            let c1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let c2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        if closed {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

/// Line plus a soft fill and a single marked peak.
struct TideView: View {
    let heart: ShareCardContent.Heart
    var color: Color = .white
    var lineWidth: CGFloat = 2.5
    var fill: Bool = true
    var peakDot: Bool = true

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size)
            ZStack(alignment: .topLeading) {
                if fill {
                    TideShape(values: heart.curve, closed: true)
                        .fill(LinearGradient(colors: [color.opacity(0.30), color.opacity(0.0)], startPoint: .top, endPoint: .bottom))
                }
                TideShape(values: heart.curve)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                if peakDot {
                    let i = heart.peakIndex
                    let x = rect.width * CGFloat(i) / CGFloat(heart.curve.count - 1)
                    let y = rect.height * (1 - CGFloat(heart.curve[i]))
                    Circle().fill(Palette.saffron)
                        .frame(width: lineWidth * 3.6, height: lineWidth * 3.6)
                        .overlay(Circle().stroke(.white, lineWidth: 1.5))
                        .position(x: x, y: y)
                }
            }
        }
    }
}

/// Lays a card out inside the format's safe area on top of its backdrop.
struct CardFrame<Content: View>: View {
    let ctx: ShareCardContext
    var scrim: Scrim = .bottom
    var alignment: Alignment = .bottomLeading
    @ViewBuilder var content: Content

    var body: some View {
        content
            .foregroundStyle(ctx.ink)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(ctx.insets)
            .frame(width: ctx.size.width, height: ctx.size.height)
            .background { Backdrop(ctx: ctx, scrim: scrim) }
            .clipped()
    }
}

/// Soft shadow that keeps bare text readable on a photo. Used by stickers,
/// which cannot bring their own scrim.
extension View {
    func overPhotoShadow() -> some View {
        self.shadow(color: .black.opacity(0.55), radius: 1, y: 0.5)
            .shadow(color: .black.opacity(0.35), radius: 9, y: 2)
    }
}

extension Color {
    func mix(with other: Color, by amount: Double) -> Color {
        let a = NSColorComponents(self), b = NSColorComponents(other)
        return Color(red: a.r + (b.r - a.r) * amount, green: a.g + (b.g - a.g) * amount, blue: a.b + (b.b - a.b) * amount)
    }
}

import AppKit
private struct NSColorComponents {
    let r: Double, g: Double, b: Double
    init(_ color: Color) {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? .black
        r = Double(ns.redComponent); g = Double(ns.greenComponent); b = Double(ns.blueComponent)
    }
}
