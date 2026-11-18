import Testing
import Foundation
import SwiftData
import SwiftUI
import UIKit
@testable import APPNAME

extension Tag {
    @Tag static var shareCards: Self
}

// MARK: - Content

@Suite("Share card content", .tags(.shareCards, .model))
@MainActor
struct ShareCardContentTests {

    @Test func testSongClock_underAndOverAnHour_formatsLikeThePlaylist() {
        #expect(ShareCardContent.Song(id: 0, title: "", artist: "", offset: 30).clock == "0:30")
        #expect(ShareCardContent.Song(id: 0, title: "", artist: "", offset: 439).clock == "7:19")
        #expect(ShareCardContent.Song(id: 0, title: "", artist: "", offset: 3712).clock == "1:01:52")
    }

    @Test func testHeartCurve_noBeats_isEmpty() {
        #expect(ShareCardContent.Heart.curve(from: [], duration: 3600).isEmpty)
        #expect(ShareCardContent.Heart.curve(from: [(offset: 10, bpm: 90)], duration: 3600).isEmpty)
        #expect(ShareCardContent.Heart.curve(from: [(offset: 0, bpm: 90), (offset: 60, bpm: 100)], duration: 0).isEmpty)
    }

    @Test func testHeartCurve_risingThenFalling_staysInRangeAndPeaksWhereTheClassDid() {
        let beats: [(offset: TimeInterval, bpm: Int)] = (0..<360).map { i in
            let t = Double(i) / 359
            return (t * 3600, Int(80 + 70 * (1 - abs(t - 0.6) / 0.6)))
        }
        let curve = ShareCardContent.Heart.curve(from: beats, duration: 3600)
        #expect(curve.count == ShareCardContent.Heart.curvePoints)
        #expect(curve.allSatisfy { (0.0...1.0).contains($0) })
        let peak = Double(curve.indices.max { curve[$0] < curve[$1] } ?? 0) / Double(curve.count - 1)
        #expect(abs(peak - 0.6) < 0.05)
    }

    @Test func testHeartCurve_gapInSamples_carriesTheLastValue() {
        // Beats only in the first and last tenth of class.
        let beats: [(offset: TimeInterval, bpm: Int)] =
            (0..<20).map { (Double($0) * 5, 90) } + (0..<20).map { (900 + Double($0) * 5, 130) }
        let curve = ShareCardContent.Heart.curve(from: beats, duration: 1000)
        #expect(curve.count == ShareCardContent.Heart.curvePoints)
        #expect(curve[curve.count / 2] == curve[5])
    }

    @Test func testInitFromSession_fullClass_readsEverythingInOrder() throws {
        let container = try ModelFixtures.makeContainer()
        let context = container.mainContext
        let session = WorkoutSession(classCategory: .yoga, title: "Vinyasa with Maya")
        session.startedAt = Date(timeIntervalSince1970: 1_793_900_000)
        session.endedAt = session.startedAt.addingTimeInterval(75 * 60)
        session.venueName = "Sunrise Yoga Loft"
        session.locationName = "1 Main St, San Francisco"
        context.insert(session)

        let teacher = UserProfile(displayName: "Maya", role: .instructor)
        context.insert(teacher)
        session.taggedInstructor = teacher

        let playlist = Playlist(name: "Class")
        playlist.songs = [
            RecognizedSong(shazamMediaID: "b", title: "Second", artist: "B", startTime: 400, endTime: 700, matchConfidence: 0.9, orderIndex: 1),
            RecognizedSong(shazamMediaID: "a", title: "First", artist: "A", startTime: 30, endTime: 390, matchConfidence: 0.9, orderIndex: 0),
        ]
        session.playlist = playlist

        let theme = SessionTheme(primaryArchetype: .breathAsAnchor, confidence: 0.8)
        theme.quotes = [
            InstructorQuote(text: "Said second.", approximateTimestamp: 900, whyItMattered: "", orderIndex: 1),
            InstructorQuote(text: "  Said first.  ", approximateTimestamp: 100, whyItMattered: "", orderIndex: 0),
            InstructorQuote(text: "   ", approximateTimestamp: 100, whyItMattered: "", orderIndex: 2),
        ]
        session.theme = theme

        session.heartRateSamples = (0..<90).map { i in
            HeartRateSample(timestamp: session.startedAt.addingTimeInterval(Double(i) * 50),
                            bpm: 90 + (i < 60 ? i : 120 - i), zone: .fatBurn)
        }

        let content = ShareCardContent(session: session)

        #expect(content.title == "Vinyasa with Maya")
        #expect(content.minutes == 75)
        #expect(content.teacher == "Maya")
        #expect(content.studio == "Sunrise Yoga Loft")
        #expect(content.songs.map(\.title) == ["First", "Second"])
        #expect(content.songs.first?.clock == "0:30")
        #expect(content.lines == ["Said first.", "Said second."])
        let heart = try #require(content.heart)
        #expect(heart.peakBPM == 150)
        #expect(heart.curve.count == ShareCardContent.Heart.curvePoints)
        // The address is never part of a card.
        #expect(!String(describing: content).contains("Main St"))
    }

    @Test func testInitFromSession_bareClass_hasNoOptionalParts() throws {
        let container = try ModelFixtures.makeContainer()
        let session = WorkoutSession(classCategory: .pilates, title: "Pilates")
        container.mainContext.insert(session)

        let content = ShareCardContent(session: session)

        #expect(content.minutes == nil)
        #expect(content.teacher == nil)
        #expect(content.studio == nil)
        #expect(content.songs.isEmpty)
        #expect(content.lines.isEmpty)
        #expect(content.heart == nil)
        #expect(!content.kicker.isEmpty)
    }
}

// MARK: - Registry, options and backgrounds

@Suite("Share card registry", .tags(.shareCards, .model))
@MainActor
struct ShareCardRegistryTests {

    static let fixtures: [(name: String, content: ShareCardContent)] = [
        ("sample", .sample), ("sparse", .sparse), ("long", .long),
    ]

    @Test func testRegistry_ids_areUnique() {
        let ids = ShareCardRegistry.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func testRegistry_firstSix_arePresent() {
        let ids = Set(ShareCardRegistry.all.map(\.id))
        #expect(ids.isSuperset(of: ["one-number", "caption", "sticker-pill", "sticker-stack", "setlist", "teacher-line", "tide"]))
    }

    @Test func testEveryStyle_anyClass_hasAtMostThreeOptionsWithUniqueIDs() {
        for style in ShareCardRegistry.all {
            for fixture in Self.fixtures {
                let options = style.options(for: fixture.content)
                #expect(options.count <= 3, "\(style.id) has \(options.count) options for the \(fixture.name) class")
                #expect(Set(options.map(\.id)).count == options.count)
                for option in options {
                    if case .choice(let choices, let fallback) = option.kind {
                        #expect(choices.contains { $0.id == fallback }, "\(style.id).\(option.id) default is not a choice")
                    }
                }
            }
        }
    }

    @Test func testEveryStyle_kind_matchesItsBackgrounds() {
        for style in ShareCardRegistry.all {
            switch style.kind {
            case .card: #expect(!style.backgrounds.isEmpty, "\(style.id) has nothing to sit on")
            case .sticker: #expect(style.backgrounds.isEmpty, "\(style.id) is a sticker and must stay clear")
            }
        }
    }

    @Test func testEveryStyle_tier_isFree() {
        // The plan: every per-class card is free. A Pro style must be a decision.
        #expect(ShareCardRegistry.all.allSatisfy { $0.tier == .free })
    }

    @Test func testAvailable_sparseClass_leavesOutWhatItCannotDraw() {
        let ids = ShareCardRegistry.available(for: .sparse).map(\.id)
        #expect(!ids.contains("teacher-line"))
        #expect(!ids.contains("tide"))
        #expect(ids.contains("setlist"))
        #expect(ids.contains("one-number"))
        #expect(ids.contains("caption"))
    }

    @Test func testAvailable_fullClass_offersEveryStyle() {
        #expect(ShareCardRegistry.available(for: .sample).count == ShareCardRegistry.all.count)
    }

    @Test func testNumberOption_sparseClass_offersOnlySongs() throws {
        let option = try #require(ShareCardNumber.option(for: .sparse))
        guard case .choice(let choices, let fallback) = option.kind else {
            Issue.record("Number must be a choice"); return
        }
        #expect(choices.map(\.id) == ["songs"])
        #expect(fallback == "songs")
        #expect(ShareCardNumber.value("songs", in: .sparse) == .init(figure: "1", unit: "song"))
        #expect(ShareCardNumber.value("minutes", in: .sparse) == nil)
    }

    @Test func testOptionValues_storedChoiceNoLongerOffered_fallsBackToDefault() {
        let option = ShareCardOption.choice("number", "Number", [.init(id: "songs", title: "Songs")])
        var values = ShareCardOptionValues()
        #expect(values.choice(option) == "songs")
        values.choices["number"] = "peak"
        #expect(values.choice(option) == "songs")
        values.choices["number"] = "songs"
        #expect(values.choice(option) == "songs")
    }

    @Test func testOptionValues_toggle_usesDefaultUntilSet() {
        let on = ShareCardOption.toggle("studio", "Studio")
        let off = ShareCardOption.toggle("bpm", "Beats per minute", default: false)
        var values = ShareCardOptionValues()
        #expect(values.isOn(on))
        #expect(!values.isOn(off))
        values.toggles["bpm"] = true
        #expect(values.isOn(off))
    }

    @Test func testTide_defaults_showWordsNotBeatsPerMinute() {
        let style = TideStyle()
        let context = ShareCardRenderer.defaultContext(for: style, content: .sample)
        #expect(!context.isOn("bpm"))
    }

    @Test func testBackgroundKind_photoChosenButNoPhoto_usesTheNextKind() {
        var values = ShareCardOptionValues()
        values.background = .photo
        #expect(ShareCardRenderer.backgroundKind(for: OneNumberStyle(), values: values, hasPhoto: false) == .colour)
        #expect(ShareCardRenderer.backgroundKind(for: OneNumberStyle(), values: values, hasPhoto: true) == .photo)
        // One Number leads with the photo when there is one.
        #expect(ShareCardRenderer.backgroundKind(for: OneNumberStyle(), values: .init(), hasPhoto: true) == .photo)
        // A kind the style does not support is ignored.
        values.background = .paper
        #expect(ShareCardRenderer.backgroundKind(for: SetlistStyle(), values: values, hasPhoto: false) == .colour)
        #expect(ShareCardRenderer.backgroundKind(for: PillSticker(), values: values, hasPhoto: true) == nil)
    }

    @Test func testHaze_onAWhitePhoto_keepsWhiteTextReadable() {
        #expect(ShareCardPalette.contrastOfWhite(onWhiteUnder: ShareCardPalette.hazeOpacity) >= 4.5)
        // The bottom scrim is darker still where One Number sets its text.
        #expect(ShareCardPalette.contrastOfWhite(onWhiteUnder: 0.55) < ShareCardPalette.contrastOfWhite(onWhiteUnder: 0.80))
    }

    @Test func testPrefs_roundTrip_keepsChoices() {
        let defaults = UserDefaults(suiteName: "share-prefs-\(UUID().uuidString)")!
        let settings = UserSettings(defaults: defaults)
        #expect(ShareStudioPrefs.load(from: settings) == ShareStudioPrefs())

        var prefs = ShareStudioPrefs()
        prefs.styleID = "setlist"
        prefs.format = .square
        prefs.field = .lagoon
        prefs.values["tide"] = ShareCardOptionValues(toggles: ["bpm": true], choices: [:], background: .dark)
        prefs.save(to: settings)

        #expect(ShareStudioPrefs.load(from: settings) == prefs)
    }

    @Test func testPrefs_unknownOrBrokenBlob_loadsDefaults() {
        let defaults = UserDefaults(suiteName: "share-prefs-\(UUID().uuidString)")!
        let settings = UserSettings(defaults: defaults)
        settings.shareStudioPrefsData = Data(#"{"format":"hexagon","styleID":"gone"}"#.utf8)
        let prefs = ShareStudioPrefs.load(from: settings)
        #expect(prefs.format == .story)
        #expect(prefs.styleID == "gone")
        settings.shareStudioPrefsData = Data("not json".utf8)
        #expect(ShareStudioPrefs.load(from: settings) == ShareStudioPrefs())
    }

    @Test func testPrefs_persistable_dropsChoicesThatBelongToOneClass() {
        var prefs = ShareStudioPrefs()
        prefs.values["teacher-line"] = ShareCardOptionValues(toggles: ["teacher": false], choices: ["line": "1"])
        let stored = prefs.persistable { id in
            ShareCardRegistry.style(id: id)?.options(for: .sample) ?? []
        }
        #expect(stored.values["teacher-line"]?.choices["line"] == nil)
        #expect(stored.values["teacher-line"]?.toggles["teacher"] == false)
    }
}

// MARK: - Rendering

@Suite("Share card rendering", .tags(.shareCards, .view))
@MainActor
struct ShareCardRenderingTests {

    /// RGBA bytes of an image at its pixel size.
    private func pixels(_ image: UIImage) throws -> (bytes: [UInt8], width: Int, height: Int) {
        let cg = try #require(image.cgImage)
        var bytes = [UInt8](repeating: 0, count: cg.width * cg.height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress, width: cg.width, height: cg.height, bitsPerComponent: 8,
                bytesPerRow: cg.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
            return true
        }
        try #require(drawn)
        return (bytes, cg.width, cg.height)
    }

    private func alpha(_ p: (bytes: [UInt8], width: Int, height: Int), x: Int, y: Int) -> UInt8 {
        p.bytes[(y * p.width + x) * 4 + 3]
    }

    private var photo: UIImage {
        // A pure white photo: the hardest case for white text.
        UIGraphicsImageRenderer(size: CGSize(width: 300, height: 400)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 300, height: 400))
        }
    }

    @Test(arguments: ShareCardFormat.allCases)
    func testCards_everyStyleAndClass_renderOpaqueAtExactPixelSize(format: ShareCardFormat) throws {
        for fixture in ShareCardRegistryTests.fixtures {
            for style in ShareCardRegistry.available(for: fixture.content) where style.kind == .card {
                let context = ShareCardRenderer.defaultContext(for: style, content: fixture.content, format: format)
                let image = try #require(ShareCardRenderer.image(style, context), "\(style.id) did not render")
                let p = try pixels(image)
                #expect(p.width == Int(format.pixelSize.width), "\(style.id) \(format.rawValue) \(fixture.name)")
                #expect(p.height == Int(format.pixelSize.height), "\(style.id) \(format.rawValue) \(fixture.name)")
                for (x, y) in [(0, 0), (p.width - 1, 0), (0, p.height - 1), (p.width - 1, p.height - 1), (p.width / 2, p.height / 2)] {
                    #expect(alpha(p, x: x, y: y) == 255, "\(style.id) has a see-through pixel at \(x),\(y)")
                }
            }
        }
    }

    @Test func testCards_everyBackgroundAStyleSupports_renders() throws {
        for style in ShareCardRegistry.all where style.kind == .card {
            for kind in style.backgrounds {
                var values = ShareCardOptionValues()
                values.background = kind
                let context = ShareCardRenderer.context(
                    for: style, content: .sample, format: .story, values: values, field: .rose, photo: photo)
                #expect(ShareCardRenderer.image(style, context, scale: 1) != nil, "\(style.id) on \(kind.rawValue)")
            }
        }
    }

    @Test func testStickers_everyClass_areTransparentAtTheCornersAndFitAStory() throws {
        for fixture in ShareCardRegistryTests.fixtures {
            for style in ShareCardRegistry.available(for: fixture.content) where style.kind == .sticker {
                let context = ShareCardRenderer.defaultContext(for: style, content: fixture.content)
                let image = try #require(ShareCardRenderer.image(style, context), "\(style.id) did not render")
                let p = try pixels(image)
                #expect(alpha(p, x: 0, y: 0) == 0, "\(style.id) corner is not clear")
                #expect(alpha(p, x: p.width - 1, y: p.height - 1) == 0, "\(style.id) corner is not clear")
                #expect(stride(from: 3, to: p.bytes.count, by: 4).contains { p.bytes[$0] == 255 }, "\(style.id) drew nothing")
                #expect(p.width <= Int(ShareCardFormat.story.pixelSize.width), "\(style.id) is wider than a Story for the \(fixture.name) class")
                #expect(p.width > 0 && p.height > 0)
            }
        }
    }

    @Test func testOptions_changingOne_changesTheCard() throws {
        let style = TideStyle()
        let words = ShareCardRenderer.defaultContext(for: style, content: .sample)
        var values = ShareCardOptionValues()
        values.toggles["bpm"] = true
        let numbers = ShareCardRenderer.context(for: style, content: .sample, format: .story, values: values, field: .indigo, photo: nil)
        let a = try #require(ShareCardRenderer.image(style, words, scale: 1)?.pngData())
        let b = try #require(ShareCardRenderer.image(style, numbers, scale: 1)?.pngData())
        #expect(a != b)
    }

    /// One reference image per style and shape. Rendered cards do not depend
    /// on the host's screen, so one set per OS runtime serves every device.
    @Test func testReferences_sampleClass_matchRecordedImages() throws {
        let folder = "ShareCardTests-iOS\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)"
        for style in ShareCardRegistry.all {
            let formats: [ShareCardFormat] = style.kind == .card ? ShareCardFormat.allCases : [.story]
            for format in formats {
                let context = ShareCardRenderer.defaultContext(for: style, content: .sample, format: format)
                let image = try #require(ShareCardRenderer.image(style, context, scale: 1))
                let name = style.kind == .card ? "\(style.id)-\(format.rawValue)" : style.id
                try Snapshot.assertMatches(image, named: name, folder: folder)
            }
        }
    }

    /// Not a check: writes every style, shape, class and font to a folder so
    /// a new style or font can be looked at. Set `SHARE_CARD_DUMP` to a directory.
    @Test(.enabled(if: !(ProcessInfo.processInfo.environment["SHARE_CARD_DUMP"] ?? "").isEmpty))
    func testDump_whenAsked_writesEveryStyleShapeClassAndFont() throws {
        let directory = URL(fileURLWithPath: try #require(ProcessInfo.processInfo.environment["SHARE_CARD_DUMP"]))
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for fixture in ShareCardRegistryTests.fixtures {
            for style in ShareCardRegistry.available(for: fixture.content) {
                let formats: [ShareCardFormat] = style.kind == .card ? ShareCardFormat.allCases : [.story]
                for format in formats {
                    for typeface in ShareCardTypeface.allCases {
                        let context = ShareCardRenderer.defaultContext(for: style, content: fixture.content, format: format, typeface: typeface)
                        let image = try #require(ShareCardRenderer.image(style, context, scale: 1))
                        try image.pngData()?.write(to: directory.appendingPathComponent(
                            "\(typeface.rawValue)-\(fixture.name)-\(style.id)-\(format.rawValue).png"))
                    }
                }
            }
        }
    }
}
