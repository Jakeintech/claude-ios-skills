import SwiftUI
import UIKit

// MARK: - Format

/// The shape of a rendered card. Designed in points at 360 wide and rendered
/// at 3×, so every card is 1080 px across.
enum ShareCardFormat: String, CaseIterable, Identifiable, Codable, Sendable {
    case story, portrait, square

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .story: CGSize(width: 360, height: 640)
        case .portrait: CGSize(width: 360, height: 450)
        case .square: CGSize(width: 360, height: 360)
        }
    }

    static let renderScale: CGFloat = 3

    var pixelSize: CGSize {
        CGSize(width: size.width * Self.renderScale, height: size.height * Self.renderScale)
    }

    /// Story keeps clear of Instagram's own header and reply bar: about
    /// 250 px at the top and 340 px at the bottom of a 1080×1920 frame.
    var insets: EdgeInsets {
        switch self {
        case .story: EdgeInsets(top: 84, leading: 26, bottom: 114, trailing: 26)
        case .portrait: EdgeInsets(top: 26, leading: 26, bottom: 26, trailing: 26)
        case .square: EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24)
        }
    }

    var displayName: String {
        switch self {
        case .story: String(localized: "Story", comment: "Share card shape: 9:16")
        case .portrait: String(localized: "Post", comment: "Share card shape: 4:5")
        case .square: String(localized: "Square", comment: "Share card shape: 1:1")
        }
    }
}

// MARK: - Background

/// A colour field for cards without a photo. Three for now; when the class
/// colour from the redesign exists it becomes the default ahead of these.
enum ShareCardField: String, CaseIterable, Identifiable, Codable, Sendable {
    case indigo, lagoon, rose

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .indigo: String(localized: "Indigo", comment: "Share card colour name")
        case .lagoon: String(localized: "Lagoon", comment: "Share card colour name")
        case .rose: String(localized: "Rose", comment: "Share card colour name")
        }
    }

    /// Mood colours from the design system: stillness, heart, flow, breath,
    /// grounding. `deep` is the dark end that holds white text.
    var colors: (primary: Color, secondary: Color, tertiary: Color, deep: Color) {
        switch self {
        case .indigo: (Color(hex: 0x5A49B8), Color(hex: 0x8A3A86), Color(hex: 0x3A4FB0), Color(hex: 0x1B1638))
        case .lagoon: (Color(hex: 0x187C7A), Color(hex: 0x3373BE), Color(hex: 0x5A49B8), Color(hex: 0x0D2433))
        case .rose: (Color(hex: 0xB03F76), Color(hex: 0x8A3D4C), Color(hex: 0x5A49B8), Color(hex: 0x2A1026))
        }
    }

    /// Top and bottom colours Instagram paints behind a sticker with no photo.
    var storyHex: (top: String, bottom: String) {
        switch self {
        case .indigo: ("#5A49B8", "#1B1638")
        case .lagoon: ("#187C7A", "#0D2433")
        case .rose: ("#B03F76", "#2A1026")
        }
    }
}

/// What a style can sit on. The picker offers a style only its own kinds.
enum ShareCardBackgroundKind: String, CaseIterable, Identifiable, Codable, Sendable {
    case colour, photo, dark, paper

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .colour: String(localized: "Colour", comment: "Share card background choice")
        case .photo: String(localized: "Photo", comment: "Share card background choice")
        case .dark: String(localized: "Dark", comment: "Share card background choice")
        case .paper: String(localized: "Paper", comment: "Share card background choice")
        }
    }
}

enum ShareCardBackground {
    case field(ShareCardField)
    case photo(UIImage)
    case ink
    case paper
    /// Stickers: nothing behind them.
    case clear

    var isLight: Bool { if case .paper = self { true } else { false } }
}

// MARK: - Options

/// One thing the person can change about a style. A style has at most three.
struct ShareCardOption: Identifiable, Sendable, Equatable {
    struct Choice: Identifiable, Sendable, Equatable {
        let id: String
        let title: String
    }

    enum Kind: Sendable, Equatable {
        case toggle(default: Bool)
        case choice([Choice], default: String)
    }

    let id: String
    let title: String
    let kind: Kind
    /// False for choices that only make sense for one class (which line).
    var persists = true

    static func toggle(_ id: String, _ title: String, default value: Bool = true) -> ShareCardOption {
        ShareCardOption(id: id, title: title, kind: .toggle(default: value))
    }

    static func choice(_ id: String, _ title: String, _ choices: [Choice], persists: Bool = true) -> ShareCardOption {
        ShareCardOption(id: id, title: title, kind: .choice(choices, default: choices.first?.id ?? ""), persists: persists)
    }
}

/// What the person chose for one style. Missing keys mean the default.
struct ShareCardOptionValues: Codable, Hashable, Sendable {
    var toggles: [String: Bool] = [:]
    var choices: [String: String] = [:]
    var background: ShareCardBackgroundKind?

    func isOn(_ option: ShareCardOption) -> Bool {
        guard case .toggle(let fallback) = option.kind else { return false }
        return toggles[option.id] ?? fallback
    }

    /// The stored choice when it is still one of the option's choices,
    /// otherwise the default.
    func choice(_ option: ShareCardOption) -> String {
        guard case .choice(let choices, let fallback) = option.kind else { return "" }
        if let stored = self.choices[option.id], choices.contains(where: { $0.id == stored }) { return stored }
        return fallback
    }
}

// MARK: - Context

/// Everything a style needs to draw one card.
struct ShareCardContext {
    let content: ShareCardContent
    let format: ShareCardFormat
    let background: ShareCardBackground
    var typeface: ShareCardTypeface = .standard
    var values = ShareCardOptionValues()
    /// The style's options for this content, so lookups know the defaults.
    var options: [ShareCardOption] = []

    var size: CGSize { format.size }
    var insets: EdgeInsets { format.insets }
    /// Text colour for this background.
    var ink: Color { background.isLight ? ShareCardPalette.ink : .white }

    func pick<T>(_ story: T, _ portrait: T, _ square: T) -> T {
        switch format {
        case .story: story
        case .portrait: portrait
        case .square: square
        }
    }

    func isOn(_ id: String) -> Bool {
        options.first { $0.id == id }.map(values.isOn) ?? false
    }

    func choice(_ id: String) -> String {
        options.first { $0.id == id }.map(values.choice) ?? ""
    }
}

// MARK: - Style

enum ShareCardGroup: String, CaseIterable, Identifiable, Sendable {
    case simple, sticker, classCard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .simple: String(localized: "Simple", comment: "Share card group")
        case .sticker: String(localized: "Stickers", comment: "Share card group")
        case .classCard: String(localized: "Class", comment: "Share card group")
        }
    }
}

enum ShareCardTier: Sendable { case free, pro }

enum ShareCardKind: Sendable {
    /// Fills the format. Opaque.
    case card
    /// Sized by its content, on a transparent background.
    case sticker
}

/// One share card design. A new style is one type that conforms to this and
/// one line in `ShareCardRegistry.all`; the picker and the tests read the
/// registry, so nothing else changes.
@MainActor
protocol ShareCardStyle: Sendable {
    /// Stable: stored in settings.
    var id: String { get }
    var name: String { get }
    var tagline: String { get }
    var group: ShareCardGroup { get }
    var kind: ShareCardKind { get }
    var tier: ShareCardTier { get }
    /// The first is the default. Stickers have none.
    var backgrounds: [ShareCardBackgroundKind] { get }
    /// At most three.
    func options(for content: ShareCardContent) -> [ShareCardOption]
    /// False when the class lacks what the style draws.
    func isAvailable(for content: ShareCardContent) -> Bool
    func body(_ context: ShareCardContext) -> AnyView
}

extension ShareCardStyle {
    var kind: ShareCardKind { .card }
    var tier: ShareCardTier { .free }
    func options(for content: ShareCardContent) -> [ShareCardOption] { [] }
    func isAvailable(for content: ShareCardContent) -> Bool { true }
}

@MainActor
enum ShareCardRegistry {
    static let all: [any ShareCardStyle] = [
        OneNumberStyle(), CaptionStyle(),
        PillSticker(), StackSticker(),
        SetlistStyle(), TeacherLineStyle(), TideStyle(),
    ]

    static func style(id: String) -> (any ShareCardStyle)? {
        all.first { $0.id == id }
    }

    /// The styles this class can use, in registry order.
    static func available(for content: ShareCardContent) -> [any ShareCardStyle] {
        all.filter { $0.isAvailable(for: content) }
    }
}

// MARK: - Renderer

@MainActor
enum ShareCardRenderer {
    /// Renders one card or sticker. Fixed traits, so the image is the same
    /// whatever text size, appearance or bold-text setting the phone uses.
    static func image(_ style: any ShareCardStyle, _ context: ShareCardContext, scale: CGFloat = ShareCardFormat.renderScale) -> UIImage? {
        let view = style.body(context)
            .environment(\.shareCardTypeface, context.typeface)
            .environment(\.dynamicTypeSize, .large)
            .environment(\.colorScheme, .dark)
            .environment(\.legibilityWeight, .regular)
            .environment(\.layoutDirection, .leftToRight)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        renderer.isOpaque = style.kind == .card
        if style.kind == .sticker {
            // A sticker is as wide as its content, up to a Story's width.
            renderer.proposedSize = ProposedViewSize(width: ShareCardFormat.story.size.width, height: nil)
        }
        return renderer.uiImage
    }

    /// The context a style gets when the person has changed nothing.
    static func defaultContext(
        for style: any ShareCardStyle,
        content: ShareCardContent,
        format: ShareCardFormat = .story,
        field: ShareCardField = .indigo,
        photo: UIImage? = nil,
        typeface: ShareCardTypeface = .standard
    ) -> ShareCardContext {
        context(for: style, content: content, format: format, values: ShareCardOptionValues(), field: field, photo: photo, typeface: typeface)
    }

    static func context(
        for style: any ShareCardStyle,
        content: ShareCardContent,
        format: ShareCardFormat,
        values: ShareCardOptionValues,
        field: ShareCardField,
        photo: UIImage?,
        typeface: ShareCardTypeface = .standard
    ) -> ShareCardContext {
        ShareCardContext(
            content: content,
            format: format,
            background: background(for: style, values: values, field: field, photo: photo),
            typeface: typeface,
            values: values,
            options: style.options(for: content)
        )
    }

    /// The chosen background kind when the style supports it and it can be
    /// drawn (a photo needs a photo), otherwise the style's first that can.
    static func backgroundKind(for style: any ShareCardStyle, values: ShareCardOptionValues, hasPhoto: Bool) -> ShareCardBackgroundKind? {
        let usable = style.backgrounds.filter { $0 != .photo || hasPhoto }
        if let chosen = values.background, usable.contains(chosen) { return chosen }
        return usable.first ?? style.backgrounds.first { $0 != .photo }
    }

    static func background(for style: any ShareCardStyle, values: ShareCardOptionValues, field: ShareCardField, photo: UIImage?) -> ShareCardBackground {
        guard style.kind == .card else { return .clear }
        switch backgroundKind(for: style, values: values, hasPhoto: photo != nil) {
        case .photo: return photo.map(ShareCardBackground.photo) ?? .field(field)
        case .dark: return .ink
        case .paper: return .paper
        case .colour, nil: return .field(field)
        }
    }
}
