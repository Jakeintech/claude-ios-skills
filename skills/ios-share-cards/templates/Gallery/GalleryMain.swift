// Gallery only: renders every style in every format to PNG, plus sheets.
// Usage: gallery <output-directory>

import AppKit
import SwiftUI

@MainActor
enum Render {
    static func image<V: View>(_ view: V, scale: CGFloat = 3, opaque: Bool = true) -> CGImage {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, .dark))
        renderer.scale = scale
        renderer.isOpaque = opaque
        guard let image = renderer.cgImage else { fatalError("render failed") }
        return image
    }

    static func write(_ image: CGImage, _ url: URL, jpeg: Bool = false) {
        let rep = NSBitmapImageRep(cgImage: image)
        let data = jpeg
            ? rep.representation(using: .jpeg, properties: [.compressionFactor: 0.86])
            : rep.representation(using: .png, properties: [:])
        try! data!.write(to: url)
    }
}

struct Checkerboard: View {
    var body: some View {
        Canvas { ctx, size in
            let s: CGFloat = 10
            for y in 0..<Int(size.height / s + 1) {
                for x in 0..<Int(size.width / s + 1) where (x + y) % 2 == 0 {
                    ctx.fill(Path(CGRect(x: CGFloat(x) * s, y: CGFloat(y) * s, width: s, height: s)), with: .color(.white.opacity(0.07)))
                }
            }
        }
        .background(Color(hex: 0x1D1A26))
    }
}

/// A labelled grid of rendered images.
struct Sheet: View {
    struct Item: Identifiable {
        let id = UUID()
        let image: CGImage
        let title: String
        var subtitle: String = ""
        var checker = false
    }

    let title: String
    let subtitle: String
    let items: [Item]
    let columns: Int
    let tileWidth: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.round(26)).foregroundStyle(.white)
                Text(subtitle).font(.round(14, .medium)).foregroundStyle(.white.opacity(0.6))
            }
            Grid(alignment: .topLeading, horizontalSpacing: 22, verticalSpacing: 26) {
                let rows = stride(from: 0, to: items.count, by: columns).map { Array(items[$0..<min($0 + columns, items.count)]) }
                ForEach(rows.indices, id: \.self) { r in
                    GridRow {
                        ForEach(rows[r]) { item in
                            VStack(alignment: .leading, spacing: 8) {
                                let aspect = CGFloat(item.image.height) / CGFloat(item.image.width)
                                Image(decorative: item.image, scale: 1)
                                    .resizable()
                                    .interpolation(.high)
                                    .frame(width: tileWidth, height: tileWidth * aspect)
                                    .background { if item.checker { Checkerboard() } }
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Text(item.title).font(.round(14, .semibold)).foregroundStyle(.white)
                                if !item.subtitle.isEmpty {
                                    Text(item.subtitle).font(.round(11.5, .medium)).foregroundStyle(.white.opacity(0.55))
                                        .frame(width: tileWidth, alignment: .leading)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(34)
        .background(Color(hex: 0x100E15))
    }
}

@main
struct Gallery {
    @MainActor
    static func main() {
        let args = CommandLine.arguments
        let out = URL(fileURLWithPath: args.count > 1 ? args[1] : "out", isDirectory: true)
        try? FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        if args.count > 2, args[2] == "fonts" {
            renderFonts(to: out)
            return
        }

        let content = ShareCardContent.demo
        let plateSize = CGSize(width: 360, height: 640)
        let studio = Render.image(StudioPlate().frame(width: plateSize.width, height: plateSize.height))
        let candle = Render.image(CandlePlate().frame(width: plateSize.width, height: plateSize.height))
        let dusk = Render.image(DuskPlate().frame(width: plateSize.width, height: plateSize.height))
        Render.write(studio, out.appendingPathComponent("plate-studio.jpg"), jpeg: true)
        Render.write(candle, out.appendingPathComponent("plate-candle.jpg"), jpeg: true)
        Render.write(dusk, out.appendingPathComponent("plate-dusk.jpg"), jpeg: true)

        // The background each style is shown on in the gallery.
        func galleryBackground(_ id: String) -> ShareCardBackground {
            switch id {
            case "one-number": .photo(dusk)
            case "caption": .photo(studio)
            case "quiet", "song": .ink
            case "month": .paper
            default: .classColour
            }
        }

        var cards: [String: CGImage] = [:]
        func card(_ style: any ShareCardStyle, _ format: ShareCardFormat, _ background: ShareCardBackground,
                  content: ShareCardContent = content, name: String) -> CGImage {
            let ctx = ShareCardContext(content: content, format: format, background: background)
            let image = Render.image(style.body(ctx))
            Render.write(image, out.appendingPathComponent("\(name).jpg"), jpeg: true)
            cards[name] = image
            return image
        }

        // 1. Every card style in every format.
        var family: [Sheet.Item] = []
        var formats: [Sheet.Item] = []
        for style in ShareCardRegistry.all where style.kind == .card {
            for format in ShareCardFormat.allCases {
                let image = card(style, format, galleryBackground(style.id), name: "\(style.id)-\(format.rawValue)")
                if format == .story {
                    family.append(.init(image: image, title: style.name, subtitle: style.tagline))
                } else {
                    formats.append(.init(image: image, title: "\(style.name) · \(format == .portrait ? "4:5" : "1:1")"))
                }
            }
        }

        // 2. Stickers: alone on transparency, and placed on a Story photo.
        var stickers: [Sheet.Item] = []
        for style in ShareCardRegistry.all where style.kind == .sticker {
            let ctx = ShareCardContext(content: content, format: .story, background: .clear)
            let sticker = Render.image(style.body(ctx), opaque: false)
            Render.write(sticker, out.appendingPathComponent("\(style.id).png"))
            let w = CGFloat(sticker.width) / 3, h = CGFloat(sticker.height) / 3
            let alone = Render.image(
                Image(decorative: sticker, scale: 3).frame(width: 360, height: 220).background(Checkerboard()))
            Render.write(alone, out.appendingPathComponent("\(style.id)-alone.jpg"), jpeg: true)
            stickers.append(.init(image: alone, title: "\(style.name) sticker", subtitle: style.tagline))

            let plate = style.id == "sticker-stack" ? dusk : (style.id == "sticker-pill" ? studio : candle)
            let position: CGPoint = switch style.id {
            case "sticker-pill": CGPoint(x: 26 + w / 2 - 10, y: 500)
            case "sticker-stack": CGPoint(x: 16 + w / 2, y: 410)
            default: CGPoint(x: 180, y: 470)
            }
            let placed = Render.image(
                ZStack {
                    Image(decorative: plate, scale: 3)
                    Image(decorative: sticker, scale: 3).frame(width: w, height: h).position(position)
                }
                .frame(width: 360, height: 640))
            Render.write(placed, out.appendingPathComponent("\(style.id)-placed.jpg"), jpeg: true)
            cards["\(style.id)-story"] = placed
            stickers.append(.init(image: placed, title: "\(style.name) on a Story", subtitle: "Placed by Instagram as a sticker: move, pinch, rotate."))
        }

        // 3. Legibility: the same cards over the bright, the dark and the busy photo.
        var legibility: [Sheet.Item] = []
        let plates: [(String, CGImage)] = [("studio", studio), ("candle", candle), ("dusk", dusk)]
        for id in ["one-number", "caption", "teacher-line", "setlist"] {
            guard let style = ShareCardRegistry.all.first(where: { $0.id == id }) else { continue }
            for (plateName, plate) in plates {
                let image = card(style, .story, .photo(plate), name: "\(id)-story-\(plateName)")
                legibility.append(.init(image: image, title: "\(style.name) · \(plateName) photo"))
            }
        }

        // 4. Class colour: the same card for three different classes.
        var moods: [Sheet.Item] = []
        for blend in [MoodBlend.stillHeart, .flowBreath, .heartGround] {
            var c = content
            c.mood = blend
            for id in ["teacher-line", "tide"] {
                guard let style = ShareCardRegistry.all.first(where: { $0.id == id }) else { continue }
                let slug = blend.name.lowercased().replacingOccurrences(of: " · ", with: "-")
                let image = card(style, .story, .classColour, content: c, name: "\(id)-story-mood-\(slug)")
                moods.append(.init(image: image, title: "\(style.name) · \(blend.name)"))
            }
        }

        // 5. Options worth seeing.
        let extras: [Sheet.Item] = [
            .init(image: card(TideStyle(showsBPM: true), .story, .ink, name: "tide-story-bpm"), title: "Tide · numbers on, dark"),
            .init(image: card(CaptionStyle(light: true), .story, .photo(candle), name: "caption-story-light"), title: "Caption · light bar"),
            .init(image: card(QuietStyle(), .story, .paper, name: "quiet-story-paper"), title: "Quiet · paper"),
            .init(image: card(TeacherLineStyle(), .story, .paper, name: "teacher-line-story-paper"), title: "Teacher's Line · paper"),
            .init(image: card(MonthStyle(), .story, .classColour, name: "month-story-colour"), title: "Month · class colour"),
            .init(image: card(TicketStyle(), .story, .photo(dusk), name: "ticket-story-dusk"), title: "Ticket · on a photo"),
        ]

        func sheet(_ name: String, _ title: String, _ subtitle: String, _ items: [Sheet.Item], columns: Int, tile: CGFloat) {
            let image = Render.image(Sheet(title: title, subtitle: subtitle, items: items, columns: columns, tileWidth: tile), scale: 2)
            Render.write(image, out.appendingPathComponent("\(name).jpg"), jpeg: true)
        }
        sheet("sheet-family", "APPNAME share cards: the family", "Eleven card styles at Story size (9:16), one class: Vinyasa with Maya, 5 Nov 2026.", family, columns: 6, tile: 200)
        sheet("sheet-formats", "The same styles at 4:5 and 1:1", "Every style reflows; nothing is cropped from the Story version.", formats, columns: 6, tile: 200)
        sheet("sheet-stickers", "Stickers", "Transparent overlays for the person's own Story photo or video.", stickers, columns: 6, tile: 200)
        sheet("sheet-legibility", "Over any photo", "Bright studio, candlelight, dusk sky. Drawn stand-ins, not real photos.", legibility, columns: 6, tile: 200)
        sheet("sheet-moods", "Class colour", "The field comes from the class's mood, so three classes give three cards.", moods, columns: 6, tile: 200)
        sheet("sheet-options", "A few options", "Each style has at most three.", extras, columns: 6, tile: 200)

        // 6. The picker, drawn.
        let strip: [(name: String, image: CGImage)] = ShareCardRegistry.all.compactMap { style in
            cards["\(style.id)-story"].map { (style.name, $0) }
        }
        func index(_ id: String) -> Int { ShareCardRegistry.all.firstIndex { $0.id == id } ?? 0 }
        func mock(_ mode: PickerMock.Mode, _ id: String, name: String) -> CGImage {
            let i = index(id)
            let style = ShareCardRegistry.all[i]
            let view = PickerMock(mode: mode, current: strip[i].image, previous: strip[max(i - 1, 0)].image,
                                  next: strip[min(i + 1, strip.count - 1)].image, strip: strip, selectedIndex: i,
                                  title: style.name, tagline: style.tagline)
            let image = Render.image(view, opaque: false)
            Render.write(image, out.appendingPathComponent("\(name).png"))
            return image
        }
        let pickerItems: [Sheet.Item] = [
            .init(image: mock(.browse, "teacher-line", name: "picker-browse"), title: "1. Browse", subtitle: "Swipe the card or tap the strip. It is always your own class."),
            .init(image: mock(.options, "teacher-line", name: "picker-options"), title: "2. Options", subtitle: "At most three per style, in one small sheet."),
            .init(image: mock(.sticker, "sticker-stack", name: "picker-sticker"), title: "3. Stickers", subtitle: "Pick your photo or video, or copy the sticker and paste it in Instagram."),
        ]
        sheet("sheet-picker", "The picker", "A drawn mock. The real screen uses system Liquid Glass controls.", pickerItems, columns: 3, tile: 300)
        print("wrote \(cards.count) cards to \(out.path)")
    }

    /// The same five cards in each typeface. Usage: gallery <dir> fonts
    @MainActor
    static func renderFonts(to out: URL) {
        let content = ShareCardContent.demo
        let dusk = Render.image(DuskPlate().frame(width: 360, height: 640))
        let cards: [(any ShareCardStyle, ShareCardBackground, ShareCardFormat)] = [
            (OneNumberStyle(), .photo(dusk), .story),
            (TeacherLineStyle(), .classColour, .story),
            (SetlistStyle(), .classColour, .story),
            (TideStyle(), .classColour, .story),
            (QuietStyle(), .ink, .square),
        ]
        var compare: [Sheet.Item] = []
        for face in Typeface.all {
            Typeface.current = face
            var row: [Sheet.Item] = []
            for (style, background, format) in cards {
                let ctx = ShareCardContext(content: content, format: format, background: background)
                let image = Render.image(style.body(ctx))
                Render.write(image, out.appendingPathComponent("font-\(face.id)-\(style.id).jpg"), jpeg: true)
                row.append(.init(image: image, title: style.name))
            }
            compare.append(.init(image: row[0].image, title: face.name, subtitle: face.faces))
            compare.append(.init(image: row[1].image, title: " ", subtitle: face.character))
            let sheet = Sheet(title: face.name, subtitle: "\(face.character) \(face.faces).", items: row, columns: 5, tileWidth: 200)
            Render.write(Render.image(sheet, scale: 2), out.appendingPathComponent("font-sheet-\(face.id).jpg"), jpeg: true)
        }
        Typeface.current = Typeface.all[0]
        let sheet = Sheet(title: "Ten typefaces for the share cards",
                          subtitle: "One Number and Teacher's Line in each. Every face ships with iOS.",
                          items: compare, columns: 10, tileWidth: 150)
        Render.write(Render.image(sheet, scale: 2), out.appendingPathComponent("font-sheet-compare.jpg"), jpeg: true)
        print("wrote \(Typeface.all.count) typefaces to \(out.path)")
    }
}
