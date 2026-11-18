import Testing
import Foundation
import UIKit
@testable import APPNAME

@Suite("Share screen model", .tags(.shareCards, .view))
@MainActor
struct ShareStudioModelTests {

    private func settings() -> UserSettings {
        UserSettings(defaults: UserDefaults(suiteName: "share-model-\(UUID().uuidString)")!)
    }

    private func store() -> ClassMemoryBackgroundStore {
        ClassMemoryBackgroundStore(containerURL: FileManager.default.temporaryDirectory
            .appendingPathComponent("share-model-\(UUID().uuidString)", isDirectory: true))
    }

    private func jpeg() throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 60, height: 80)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 60, height: 80))
        }
        return try #require(image.jpegData(compressionQuality: 0.8))
    }

    @Test func testLoad_fullClass_offersEveryStyleAndSelectsTheFirst() {
        let model = ShareStudioModel(settings: settings(), photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)
        #expect(model.styleIDs == ShareCardRegistry.all.map(\.id))
        #expect(model.selectedID == ShareCardRegistry.all.first?.id)
    }

    @Test func testLoad_rememberedStyle_isSelectedWhenTheClassCanUseIt() {
        let settings = settings()
        var prefs = ShareStudioPrefs()
        prefs.styleID = "tide"
        prefs.save(to: settings)

        let full = ShareStudioModel(settings: settings, photoStore: store())
        full.load(.sample, sessionID: UUID(), photo: nil)
        #expect(full.selectedID == "tide")

        // No heart rate: Tide is not offered, so the first style is.
        let sparse = ShareStudioModel(settings: settings, photoStore: store())
        sparse.load(.sparse, sessionID: UUID(), photo: nil)
        #expect(!sparse.styleIDs.contains("tide"))
        #expect(sparse.selectedID == sparse.styleIDs.first)
    }

    @Test func testSetToggle_persistsAndChangesTheRenderKey() {
        let settings = settings()
        let model = ShareStudioModel(settings: settings, photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)
        let before = model.renderKey(for: "tide")

        model.setToggle("bpm", true, for: "tide")

        #expect(model.renderKey(for: "tide") != before)
        #expect(model.renderKey(for: "setlist") == model.renderKey(for: "setlist"))
        #expect(ShareStudioPrefs.load(from: settings).values["tide"]?.toggles["bpm"] == true)
    }

    @Test func testSetChoice_whichLine_appliesNowButIsNotRemembered() {
        let settings = settings()
        let model = ShareStudioModel(settings: settings, photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)

        model.setChoice("line", "1", for: "teacher-line")

        #expect(model.values(for: "teacher-line").choices["line"] == "1")
        #expect(ShareStudioPrefs.load(from: settings).values["teacher-line"]?.choices["line"] == nil)
    }

    @Test func testRememberSelection_andFormat_arePersisted() {
        let settings = settings()
        let model = ShareStudioModel(settings: settings, photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)

        model.select("setlist")
        model.rememberSelection()
        model.prefs.format = .square

        let stored = ShareStudioPrefs.load(from: settings)
        #expect(stored.styleID == "setlist")
        #expect(stored.format == .square)
    }

    @Test func testPhoto_addingOne_putsItBehindTheCurrentStyleAndRemovingFallsBack() throws {
        let model = ShareStudioModel(settings: settings(), photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)
        model.select("setlist")
        #expect(model.backgroundKinds(for: "setlist") == [.colour, .dark])
        #expect(model.backgroundKind(for: "setlist") == .colour)

        model.setPhoto(try jpeg())

        #expect(model.photo != nil)
        #expect(model.backgroundKinds(for: "setlist").contains(.photo))
        #expect(model.backgroundKind(for: "setlist") == .photo)

        model.removePhoto()

        #expect(model.photo == nil)
        #expect(model.backgroundKind(for: "setlist") == .colour)
    }

    @Test func testRenderPreview_cardAndSticker_produceImagesOnce() throws {
        let model = ShareStudioModel(settings: settings(), photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)

        model.renderPreview("one-number")
        model.renderPreview("sticker-stack")
        model.renderThumbnail("tide")

        let card = try #require(model.previews["one-number"])
        let sticker = try #require(model.previews["sticker-stack"])
        // A sticker previews on a Story-shaped background.
        #expect(abs(sticker.size.height / sticker.size.width - 16.0 / 9.0) < 0.01)
        #expect(model.thumbnails["tide"] != nil)

        // Nothing changed, so nothing is drawn again.
        model.renderPreview("one-number")
        #expect(model.previews["one-number"] === card)
    }

    @Test func testExport_cardFollowsTheShapeAndStickerKeepsItsTransparency() throws {
        let model = ShareStudioModel(settings: settings(), photoStore: store())
        model.load(.sample, sessionID: UUID(), photo: nil)
        model.prefs.format = .portrait

        let card = try #require(model.exportImage("setlist")?.cgImage)
        #expect(card.width == 1080)
        #expect(card.height == 1350)

        let sticker = try #require(model.exportImage("sticker-pill")?.cgImage)
        #expect(sticker.alphaInfo != .none)
        let story = try #require(model.exportStickerStory("sticker-pill")?.cgImage)
        #expect(story.width == 1080)
        #expect(story.height == 1920)
        #expect(model.exportStickerStory("setlist") == nil)
    }
}
