import SwiftUI

/// The typeface a share card is set in. Every face ships with iOS, so none
/// needs a font file in the app.
///
/// A typeface fills four roles: `display` (hero numbers and titles), `text`
/// (small labels), `words` (the teacher's line) and `clock` (song times).
/// Tall is the standard; choosing another is part of Pro.
enum ShareCardTypeface: String, CaseIterable, Identifiable, Codable, Sendable {
    case tall, rounded, plain, wide, editorial, avenir, futura, didot, din, mono

    static let standard: ShareCardTypeface = .tall

    var id: String { rawValue }

    /// The standard face is everyone's. The rest are a Pro choice.
    var isFree: Bool { self == Self.standard }

    /// What a person gets: their stored choice with Pro, the standard without.
    /// The stored choice is kept, so it comes back if Pro does.
    static func effective(raw: String?, isPro: Bool) -> ShareCardTypeface {
        guard isPro, let raw, let chosen = ShareCardTypeface(rawValue: raw) else { return standard }
        return chosen
    }

    var displayName: String {
        switch self {
        case .tall: String(localized: "Tall", comment: "Share card font name")
        case .rounded: String(localized: "Rounded", comment: "Share card font name")
        case .plain: String(localized: "Plain", comment: "Share card font name")
        case .wide: String(localized: "Wide", comment: "Share card font name")
        case .editorial: String(localized: "Editorial", comment: "Share card font name")
        case .avenir: String(localized: "Avenir", comment: "Share card font name")
        case .futura: String(localized: "Futura", comment: "Share card font name")
        case .didot: String(localized: "Didot", comment: "Share card font name")
        case .din: String(localized: "DIN", comment: "Share card font name")
        case .mono: String(localized: "Mono", comment: "Share card font name")
        }
    }

    /// What it feels like, in a few words.
    var character: String {
        switch self {
        case .tall: String(localized: "Poster numbers, narrow and tall.", comment: "Share card font description")
        case .rounded: String(localized: "Friendly and soft.", comment: "Share card font description")
        case .plain: String(localized: "Neutral and crisp.", comment: "Share card font description")
        case .wide: String(localized: "Wide letters, lots of air.", comment: "Share card font description")
        case .editorial: String(localized: "A magazine page, in serif.", comment: "Share card font description")
        case .avenir: String(localized: "Calm and geometric.", comment: "Share card font description")
        case .futura: String(localized: "Sharp, a little retro.", comment: "Share card font description")
        case .didot: String(localized: "High contrast and elegant.", comment: "Share card font description")
        case .din: String(localized: "Sporty, like a timing board.", comment: "Share card font description")
        case .mono: String(localized: "A receipt from class.", comment: "Share card font description")
        }
    }

    // MARK: Roles

    /// Hero numbers and titles.
    func display(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        switch self {
        case .tall:
            // Hero numbers go all the way narrow; titles stay readable.
            .system(size: size, weight: weight).width(size >= Self.numeralSize ? .compressed : .condensed)
        case .rounded: .system(size: size, weight: weight, design: .rounded)
        case .plain: .system(size: size, weight: weight)
        case .wide: .system(size: size, weight: weight).width(.expanded)
        case .editorial: .system(size: size, weight: weight == .bold ? .semibold : weight, design: .serif)
        case .avenir: Self.named(Self.avenirFaces, size, weight)
        case .futura: Self.named(Self.futuraFaces, size, weight)
        case .didot: Self.named(Self.didotFaces, size, weight)
        case .din: .custom(size >= Self.numeralSize ? "DINCondensed-Bold" : "DINAlternate-Bold", fixedSize: size)
        case .mono: .system(size: size, weight: weight == .bold ? .semibold : weight, design: .monospaced)
        }
    }

    /// Small labels.
    func text(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        switch self {
        case .tall: .system(size: size, weight: weight).width(.condensed)
        case .rounded: .system(size: size, weight: weight, design: .rounded)
        case .plain, .wide, .editorial, .didot: .system(size: size, weight: weight)
        case .avenir: Self.named(Self.avenirFaces, size, weight)
        case .futura: Self.named(Self.futuraFaces, size, weight)
        case .din: .custom("DINAlternate-Bold", fixedSize: size)
        case .mono: .system(size: size, weight: weight, design: .monospaced)
        }
    }

    /// The teacher's own words: always a serif italic.
    func words(_ size: CGFloat) -> Font {
        switch self {
        case .avenir: .custom("IowanOldStyle-Italic", fixedSize: size)
        case .futura: .custom("BodoniSvtyTwoITCTT-BookIta", fixedSize: size)
        case .didot: .custom("Didot-Italic", fixedSize: size)
        default: .system(size: size, weight: .regular, design: .serif).italic()
        }
    }

    /// Song times.
    func clock(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        switch self {
        case .din: .custom("DINAlternate-Bold", fixedSize: size)
        default: .system(size: size, weight: weight, design: .monospaced)
        }
    }

    // MARK: Fit

    /// Sizes at or above this are hero numbers; at or above `titleSize`,
    /// titles; below it, small labels.
    static let numeralSize: CGFloat = 60
    static let titleSize: CGFloat = 20

    /// Narrow faces can set hero numbers taller; wide ones need them smaller.
    var numeralScale: CGFloat {
        switch self {
        case .tall: 1.28
        case .din: 1.25
        case .wide: 0.78
        case .futura, .mono: 0.86
        case .editorial: 0.94
        default: 1
        }
    }

    /// Wide faces set titles and labels a little smaller so lines still fit.
    var titleScale: CGFloat {
        switch self {
        case .wide: 0.8
        case .mono: 0.86
        default: 1
        }
    }

    var textScale: CGFloat { self == .mono ? 0.86 : 1 }

    var wordsScale: CGFloat {
        switch self {
        case .futura: 1.12
        case .didot: 0.94
        default: 1
        }
    }

    /// The font for a size a style asked for, with this face's fit applied.
    func font(_ size: CGFloat, _ weight: Font.Weight) -> Font {
        if size >= Self.numeralSize { return display(size * numeralScale, weight) }
        if size >= Self.titleSize { return display(size * titleScale, weight) }
        return text(size * textScale, weight)
    }

    // MARK: Named faces

    private static let avenirFaces: [(Font.Weight, String)] = [
        (.regular, "AvenirNext-Regular"), (.medium, "AvenirNext-Medium"), (.semibold, "AvenirNext-DemiBold"),
        (.bold, "AvenirNext-Bold"), (.heavy, "AvenirNext-Heavy"),
    ]
    private static let futuraFaces: [(Font.Weight, String)] = [(.medium, "Futura-Medium"), (.bold, "Futura-Bold")]
    private static let didotFaces: [(Font.Weight, String)] = [(.regular, "Didot"), (.bold, "Didot-Bold")]

    private static let weightOrder: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]

    /// The face in a family closest to the weight asked for.
    private static func named(_ faces: [(Font.Weight, String)], _ size: CGFloat, _ weight: Font.Weight) -> Font {
        .custom(nearestName(in: faces, to: weight), fixedSize: size)
    }

    static func nearestName(in faces: [(Font.Weight, String)], to weight: Font.Weight) -> String {
        let wanted = weightOrder.firstIndex(of: weight) ?? 3
        let best = faces.min { a, b in
            abs((weightOrder.firstIndex(of: a.0) ?? 3) - wanted) < abs((weightOrder.firstIndex(of: b.0) ?? 3) - wanted)
        }
        return best?.1 ?? ""
    }

    /// Every named font this face asks iOS for. A test checks they exist.
    var fontNames: [String] {
        switch self {
        case .avenir: Self.avenirFaces.map(\.1) + ["IowanOldStyle-Italic"]
        case .futura: Self.futuraFaces.map(\.1) + ["BodoniSvtyTwoITCTT-BookIta"]
        case .didot: Self.didotFaces.map(\.1) + ["Didot-Italic"]
        case .din: ["DINCondensed-Bold", "DINAlternate-Bold"]
        default: []
        }
    }
}

// MARK: - Applying it

extension EnvironmentValues {
    /// Set once by `ShareCardRenderer`; every card font reads it.
    @Entry var shareCardTypeface: ShareCardTypeface = .standard
}

private struct ShareCardFontModifier: ViewModifier {
    enum Role {
        case sized(CGFloat, Font.Weight)
        case words(CGFloat)
        case clock(CGFloat, Font.Weight)
    }

    let role: Role
    @Environment(\.shareCardTypeface) private var typeface

    func body(content: Content) -> some View {
        switch role {
        case .sized(let size, let weight): content.font(typeface.font(size, weight))
        case .words(let size): content.font(typeface.words(size * typeface.wordsScale))
        case .clock(let size, let weight): content.font(typeface.clock(size, weight))
        }
    }
}

// Fixed sizes are deliberate: cards are rendered images with fixed traits
// (see `ShareCardRenderer`), never interactive UI.
extension View {
    /// Numbers, titles and labels, in the card's typeface.
    func cardFont(_ size: CGFloat, _ weight: Font.Weight = .bold) -> some View {
        modifier(ShareCardFontModifier(role: .sized(size, weight)))
    }

    /// The teacher's own words. Nothing else uses it.
    func cardWords(_ size: CGFloat) -> some View {
        modifier(ShareCardFontModifier(role: .words(size)))
    }

    /// Song times.
    func cardClock(_ size: CGFloat, _ weight: Font.Weight = .medium) -> some View {
        modifier(ShareCardFontModifier(role: .clock(size, weight)))
    }
}
