// Gallery only: ten typeface options for the share cards.
//
// Every face here ships with iOS, so none needs a font file in the app.
// A typeface gives four roles: display (numbers and titles), text (small
// labels), words (the teacher's line) and clock (song times).

import SwiftUI

struct Typeface {
    let id: String
    let name: String
    /// What it feels like, in a few words.
    let character: String
    /// The faces used, for the caption.
    let faces: String
    let display: (CGFloat, Font.Weight) -> Font
    let text: (CGFloat, Font.Weight) -> Font
    let words: (CGFloat) -> Font
    let clock: (CGFloat, Font.Weight) -> Font
    /// Wide faces need smaller hero numbers; narrow ones can go taller.
    var numeralScale: CGFloat = 1
    var wordsScale: CGFloat = 1
    /// Wide faces set titles and small labels a little smaller so lines
    /// still fit the card.
    var titleScale: CGFloat = 1
    var textScale: CGFloat = 1

    nonisolated(unsafe) static var current = Typeface.all[0]

    /// A named font family: the closest face at or below the asked weight.
    static func named(_ faces: [(Font.Weight, String)]) -> (CGFloat, Font.Weight) -> Font {
        let order: [Font.Weight] = [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black]
        return { size, weight in
            let wanted = order.firstIndex(of: weight) ?? 3
            let best = faces.min { a, b in
                abs((order.firstIndex(of: a.0) ?? 3) - wanted) < abs((order.firstIndex(of: b.0) ?? 3) - wanted)
            }
            return .custom(best?.1 ?? "", fixedSize: size)
        }
    }

    static func system(_ design: Font.Design, width: Font.Width = .standard) -> (CGFloat, Font.Weight) -> Font {
        { size, weight in .system(size: size, weight: weight, design: design).width(width) }
    }

    static let newYorkItalic: (CGFloat) -> Font = { .system(size: $0, weight: .regular, design: .serif).italic() }
    static let mono = system(.monospaced)

    static let all: [Typeface] = [
        Typeface(
            id: "rounded", name: "Rounded", character: "Friendly and soft. What the cards use today.",
            faces: "SF Rounded · New York Italic",
            display: system(.rounded), text: system(.rounded), words: newYorkItalic, clock: mono),
        Typeface(
            id: "plain", name: "Plain", character: "Neutral and crisp. Looks like iOS itself.",
            faces: "SF Pro · New York Italic",
            display: system(.default), text: system(.default), words: newYorkItalic, clock: mono),
        Typeface(
            id: "wide", name: "Wide", character: "Confident and current. Wide letters, lots of air.",
            faces: "SF Pro Expanded · SF Pro · New York Italic",
            display: system(.default, width: .expanded), text: system(.default), words: newYorkItalic, clock: mono,
            numeralScale: 0.78, titleScale: 0.8),
        Typeface(
            id: "tall", name: "Tall", character: "Poster numbers. Narrow, tall and loud.",
            faces: "SF Pro Compressed · SF Pro Condensed · New York Italic",
            display: { size, weight in
                .system(size: size, weight: weight).width(size >= 60 ? .compressed : .condensed)
            },
            text: system(.default, width: .condensed), words: newYorkItalic, clock: mono,
            numeralScale: 1.28),
        Typeface(
            id: "editorial", name: "Editorial", character: "A magazine page. Serif titles and numbers.",
            faces: "New York · SF Pro · New York Italic",
            display: { size, weight in .system(size: size, weight: weight == .bold ? .semibold : weight, design: .serif) },
            text: system(.default), words: newYorkItalic, clock: mono,
            numeralScale: 0.94),
        Typeface(
            id: "avenir", name: "Avenir", character: "Calm and geometric. Warm without being round.",
            faces: "Avenir Next · Iowan Old Style Italic",
            display: named([(.medium, "AvenirNext-Medium"), (.semibold, "AvenirNext-DemiBold"), (.bold, "AvenirNext-Bold"), (.heavy, "AvenirNext-Heavy")]),
            text: named([(.regular, "AvenirNext-Regular"), (.medium, "AvenirNext-Medium"), (.semibold, "AvenirNext-DemiBold"), (.bold, "AvenirNext-Bold")]),
            words: { .custom("IowanOldStyle-Italic", fixedSize: $0) }, clock: mono),
        Typeface(
            id: "futura", name: "Futura", character: "Fashion and geometry. Sharp, a little retro.",
            faces: "Futura · Bodoni 72 Italic",
            display: named([(.medium, "Futura-Medium"), (.bold, "Futura-Bold")]),
            text: named([(.medium, "Futura-Medium"), (.bold, "Futura-Bold")]),
            words: { .custom("BodoniSvtyTwoITCTT-BookIta", fixedSize: $0) }, clock: mono,
            numeralScale: 0.86, wordsScale: 1.12),
        Typeface(
            id: "didot", name: "Didot", character: "High contrast and elegant. Reads as luxury.",
            faces: "Didot · SF Pro · Didot Italic",
            display: named([(.regular, "Didot"), (.bold, "Didot-Bold")]),
            text: system(.default),
            words: { .custom("Didot-Italic", fixedSize: $0) }, clock: mono,
            wordsScale: 0.94),
        Typeface(
            id: "din", name: "DIN", character: "Timing-board numbers. Sporty and exact.",
            faces: "DIN Condensed · DIN Alternate · New York Italic",
            display: { size, _ in .custom(size >= 60 ? "DINCondensed-Bold" : "DINAlternate-Bold", fixedSize: size) },
            text: { size, _ in .custom("DINAlternate-Bold", fixedSize: size) },
            words: newYorkItalic,
            clock: { size, _ in .custom("DINAlternate-Bold", fixedSize: size) },
            numeralScale: 1.25),
        Typeface(
            id: "mono", name: "Mono", character: "A receipt from class. Quiet, technical, modern.",
            faces: "SF Mono · New York Italic",
            display: { size, weight in .system(size: size, weight: weight == .bold ? .semibold : weight, design: .monospaced) },
            text: mono, words: newYorkItalic, clock: mono,
            numeralScale: 0.86, titleScale: 0.86, textScale: 0.86),
    ]
}
