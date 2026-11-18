import Testing
import Foundation
import SwiftUI
import UIKit
@testable import APPNAME

@Suite("Share card typefaces", .tags(.shareCards, .view))
@MainActor
struct ShareCardTypefaceTests {

    // MARK: Who gets what

    @Test func testStandard_isTall_andTheOnlyFreeFont() {
        #expect(ShareCardTypeface.standard == .tall)
        #expect(ShareCardTypeface.allCases.filter(\.isFree) == [.tall])
        #expect(ShareCardTypeface.allCases.count == 10)
    }

    @Test func testEffective_withoutPro_isAlwaysTheStandard() {
        for typeface in ShareCardTypeface.allCases {
            #expect(ShareCardTypeface.effective(raw: typeface.rawValue, isPro: false) == .tall)
        }
        #expect(ShareCardTypeface.effective(raw: nil, isPro: false) == .tall)
    }

    @Test func testEffective_withPro_isTheStoredChoice() {
        for typeface in ShareCardTypeface.allCases {
            #expect(ShareCardTypeface.effective(raw: typeface.rawValue, isPro: true) == typeface)
        }
    }

    @Test func testEffective_withProButNothingOrNonsenseStored_isTheStandard() {
        #expect(ShareCardTypeface.effective(raw: nil, isPro: true) == .tall)
        #expect(ShareCardTypeface.effective(raw: "comic-sans", isPro: true) == .tall)
    }

    @Test func testModel_typeface_followsTheSettingOnlyWithPro() {
        let settings = UserSettings(defaults: UserDefaults(suiteName: "share-typeface-\(UUID().uuidString)")!)
        let store = ClassMemoryBackgroundStore(containerURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("share-typeface-\(UUID().uuidString)", isDirectory: true))
        let model = ShareStudioModel(settings: settings, photoStore: store)
        model.load(.sample, sessionID: UUID(), photo: nil)
        #expect(model.typeface == .tall)

        settings.shareCardTypefaceRaw = ShareCardTypeface.editorial.rawValue
        #expect(model.typeface == .tall)
        let free = model.renderKey(for: "one-number")

        settings.isProUser = true
        #expect(model.typeface == .editorial)
        #expect(model.renderKey(for: "one-number") != free)

        // Pro ends: the cards go back to the standard, the choice is kept.
        settings.isProUser = false
        #expect(model.typeface == .tall)
        #expect(settings.shareCardTypefaceRaw == ShareCardTypeface.editorial.rawValue)
    }

    // MARK: The fonts themselves

    @Test(arguments: ShareCardTypeface.allCases)
    func testNamedFonts_everyFace_shipWithIOS(typeface: ShareCardTypeface) {
        for name in typeface.fontNames {
            #expect(UIFont(name: name, size: 12) != nil, "\(typeface.rawValue) asks for \(name), which this iOS does not have")
        }
    }

    @Test func testNearestName_picksTheClosestWeightInAFamily() {
        let faces: [(Font.Weight, String)] = [(.regular, "R"), (.semibold, "S"), (.heavy, "H")]
        #expect(ShareCardTypeface.nearestName(in: faces, to: .regular) == "R")
        #expect(ShareCardTypeface.nearestName(in: faces, to: .medium) == "R")
        #expect(ShareCardTypeface.nearestName(in: faces, to: .bold) == "S")
        #expect(ShareCardTypeface.nearestName(in: faces, to: .black) == "H")
        #expect(ShareCardTypeface.nearestName(in: [], to: .bold) == "")
    }

    @Test func testNames_everyFace_hasANameAndADescription() {
        for typeface in ShareCardTypeface.allCases {
            #expect(!typeface.displayName.isEmpty)
            #expect(!typeface.character.isEmpty)
        }
        #expect(Set(ShareCardTypeface.allCases.map(\.displayName)).count == ShareCardTypeface.allCases.count)
    }

    // MARK: Rendering

    @Test(arguments: ShareCardTypeface.allCases)
    func testCards_everyStyleShapeAndClass_renderAtExactSize(typeface: ShareCardTypeface) throws {
        for fixture in ShareCardRegistryTests.fixtures {
            for style in ShareCardRegistry.available(for: fixture.content) {
                let formats: [ShareCardFormat] = style.kind == .card ? ShareCardFormat.allCases : [.story]
                for format in formats {
                    let context = ShareCardRenderer.defaultContext(for: style, content: fixture.content, format: format, typeface: typeface)
                    let image = try #require(ShareCardRenderer.image(style, context, scale: 1),
                                             "\(style.id) did not render in \(typeface.rawValue)")
                    if style.kind == .card {
                        #expect(image.size == format.size, "\(style.id) \(format.rawValue) \(fixture.name) in \(typeface.rawValue)")
                    } else {
                        #expect(image.size.width <= ShareCardFormat.story.size.width,
                                "\(style.id) is wider than a Story for the \(fixture.name) class in \(typeface.rawValue)")
                    }
                }
            }
        }
    }

    /// A long title wraps; the sticker must grow to hold every line rather
    /// than cut the last one off at its bottom edge.
    @Test(arguments: ShareCardTypeface.allCases)
    func testStackSticker_longClass_isNotCutOffAtTheBottom(typeface: ShareCardTypeface) throws {
        let style = StackSticker()
        let context = ShareCardRenderer.defaultContext(for: style, content: .long, typeface: typeface)
        let image = try #require(ShareCardRenderer.image(style, context, scale: 1)?.cgImage)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let bitmap = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            bitmap.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        try #require(drawn)
        // The bottom edge is margin: soft shadow at most, never solid type.
        let lastRow = (image.height - 1) * image.width * 4
        let solid = stride(from: lastRow + 3, to: lastRow + image.width * 4, by: 4).contains { bytes[$0] > 200 }
        #expect(!solid, "Stack sticker is cut off at the bottom in \(typeface.rawValue)")
        #expect(image.width <= Int(ShareCardFormat.story.size.width))
    }

    @Test func testTypeface_changingIt_changesTheCard() throws {
        let style = OneNumberStyle()
        var seen: Set<Data> = []
        for typeface in ShareCardTypeface.allCases {
            let context = ShareCardRenderer.defaultContext(for: style, content: .sample, typeface: typeface)
            seen.insert(try #require(ShareCardRenderer.image(style, context, scale: 1)?.pngData()))
        }
        #expect(seen.count == ShareCardTypeface.allCases.count)
    }

    @Test func testDefaultContext_usesTheStandardFont() {
        let context = ShareCardRenderer.defaultContext(for: OneNumberStyle(), content: .sample)
        #expect(context.typeface == .tall)
    }

    /// One reference image per font: the hero number card.
    @Test func testReferences_everyFace_matchRecordedImages() throws {
        let folder = "ShareCardTests-iOS\(ProcessInfo.processInfo.operatingSystemVersion.majorVersion)"
        let style = OneNumberStyle()
        for typeface in ShareCardTypeface.allCases {
            let context = ShareCardRenderer.defaultContext(for: style, content: .sample, typeface: typeface)
            let image = try #require(ShareCardRenderer.image(style, context, scale: 1))
            try Snapshot.assertMatches(image, named: "typeface-\(typeface.rawValue)", folder: folder)
        }
    }
}
