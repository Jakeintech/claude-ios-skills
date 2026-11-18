import SwiftUI
import UIKit

/// State for the share screen: the class as card content, the styles it can
/// use, what the person has chosen, and the rendered previews.
@MainActor
@Observable
final class ShareStudioModel {
    /// What a rendered preview depends on. A preview is drawn again only
    /// when its key changes.
    struct RenderKey: Hashable {
        let styleID: String
        let format: ShareCardFormat
        let values: ShareCardOptionValues
        let field: ShareCardField
        let photo: ObjectIdentifier?
        let typeface: ShareCardTypeface
    }

    private(set) var content: ShareCardContent?
    private(set) var styleIDs: [String] = []
    var selectedID: String?
    private(set) var photo: UIImage?
    private(set) var previews: [String: UIImage] = [:]
    private(set) var thumbnails: [String: UIImage] = [:]

    var prefs: ShareStudioPrefs {
        didSet {
            guard prefs != oldValue else { return }
            let content = self.content
            prefs.persistable { id in
                content.flatMap { ShareCardRegistry.style(id: id)?.options(for: $0) } ?? []
            }.save(to: settings)
        }
    }

    private let settings: UserSettings
    private let photoStore: ClassMemoryBackgroundStore
    private var sessionID: UUID?
    @ObservationIgnored private var previewKeys: [String: RenderKey] = [:]
    @ObservationIgnored private var thumbnailKeys: [String: RenderKey] = [:]

    init(settings: UserSettings = .shared, photoStore: ClassMemoryBackgroundStore = .shared) {
        self.settings = settings
        self.photoStore = photoStore
        prefs = ShareStudioPrefs.load(from: settings)
    }

    // MARK: Loading

    func load(_ session: WorkoutSession) {
        let content = ShareCardContent(session: session)
        load(content, sessionID: session.id, photo: photoStore.loadImage(for: session.id))
    }

    /// Split from `load(_:)` so tests can load a fixture.
    func load(_ content: ShareCardContent, sessionID: UUID?, photo: UIImage?) {
        self.content = content
        self.sessionID = sessionID
        self.photo = photo
        styleIDs = ShareCardRegistry.available(for: content).map(\.id)
        if let remembered = prefs.styleID, styleIDs.contains(remembered) {
            selectedID = remembered
        } else {
            selectedID = styleIDs.first
        }
    }

    // MARK: Reading

    /// The font the cards are set in: the person's choice with Pro, the
    /// standard without.
    var typeface: ShareCardTypeface {
        ShareCardTypeface.effective(raw: settings.shareCardTypefaceRaw, isPro: settings.isProUser)
    }

    var selectedStyle: (any ShareCardStyle)? {
        selectedID.flatMap(ShareCardRegistry.style(id:))
    }

    func style(_ id: String) -> (any ShareCardStyle)? { ShareCardRegistry.style(id: id) }

    func values(for styleID: String) -> ShareCardOptionValues {
        prefs.values[styleID] ?? ShareCardOptionValues()
    }

    func options(for styleID: String) -> [ShareCardOption] {
        guard let content, let style = style(styleID) else { return [] }
        return style.options(for: content)
    }

    /// The background kinds to offer for a style: its own, less Photo until
    /// there is a photo.
    func backgroundKinds(for styleID: String) -> [ShareCardBackgroundKind] {
        (style(styleID)?.backgrounds ?? []).filter { $0 != .photo || photo != nil }
    }

    func backgroundKind(for styleID: String) -> ShareCardBackgroundKind? {
        guard let style = style(styleID) else { return nil }
        return ShareCardRenderer.backgroundKind(for: style, values: values(for: styleID), hasPhoto: photo != nil)
    }

    /// Whether a photo changes what this style draws or sends.
    func usesPhoto(_ styleID: String) -> Bool {
        guard let style = style(styleID) else { return false }
        return style.kind == .sticker || style.backgrounds.contains(.photo)
    }

    // MARK: Choosing

    func select(_ styleID: String) {
        guard styleIDs.contains(styleID) else { return }
        selectedID = styleID
    }

    /// Called when the pager settles, so the choice is remembered.
    func rememberSelection() {
        if let selectedID, prefs.styleID != selectedID { prefs.styleID = selectedID }
    }

    func setToggle(_ optionID: String, _ isOn: Bool, for styleID: String) {
        var values = values(for: styleID)
        values.toggles[optionID] = isOn
        prefs.values[styleID] = values
    }

    func setChoice(_ optionID: String, _ choice: String, for styleID: String) {
        var values = values(for: styleID)
        values.choices[optionID] = choice
        prefs.values[styleID] = values
    }

    func setBackground(_ kind: ShareCardBackgroundKind, for styleID: String) {
        var values = values(for: styleID)
        values.background = kind
        prefs.values[styleID] = values
    }

    /// Stores the photo for this class only, and puts it behind the current
    /// style when that style can show one.
    func setPhoto(_ data: Data) {
        guard let sessionID, let stored = photoStore.savePhoto(data, for: sessionID) else { return }
        photo = stored
        if let selectedID, style(selectedID)?.backgrounds.contains(.photo) == true {
            setBackground(.photo, for: selectedID)
        }
    }

    func removePhoto() {
        if let sessionID { photoStore.removePhoto(for: sessionID) }
        photo = nil
    }

    // MARK: Rendering

    func renderKey(for styleID: String, thumbnail: Bool = false) -> RenderKey {
        // Thumbnails are always Story-shaped so the strip stays even.
        RenderKey(styleID: styleID, format: thumbnail ? .story : prefs.format, values: values(for: styleID),
                  field: prefs.field, photo: photo.map(ObjectIdentifier.init), typeface: typeface)
    }

    private func context(for style: any ShareCardStyle, format: ShareCardFormat) -> ShareCardContext? {
        guard let content else { return nil }
        return ShareCardRenderer.context(for: style, content: content, format: format,
                                         values: values(for: style.id), field: prefs.field, photo: photo,
                                         typeface: typeface)
    }

    /// The card, or for a sticker the sticker on its Story background.
    private func display(_ style: any ShareCardStyle, format: ShareCardFormat, scale: CGFloat) -> UIImage? {
        guard let context = context(for: style, format: format) else { return nil }
        switch style.kind {
        case .card:
            return ShareCardRenderer.image(style, context, scale: scale)
        case .sticker:
            guard let sticker = ShareCardRenderer.image(style, context) else { return nil }
            return StickerStoryRenderer.composite(sticker: sticker, photo: photo, field: prefs.field, scale: scale)
        }
    }

    func renderPreview(_ styleID: String) {
        let key = renderKey(for: styleID)
        guard previewKeys[styleID] != key, let style = style(styleID) else { return }
        previewKeys[styleID] = key
        previews[styleID] = display(style, format: key.format, scale: 2)
    }

    func renderThumbnail(_ styleID: String) {
        let key = renderKey(for: styleID, thumbnail: true)
        guard thumbnailKeys[styleID] != key, let style = style(styleID) else { return }
        thumbnailKeys[styleID] = key
        thumbnails[styleID] = display(style, format: .story, scale: 0.5)
    }

    // MARK: Exporting

    /// Full size: the card at 1080 px wide, or the sticker alone with alpha.
    func exportImage(_ styleID: String) -> UIImage? {
        guard let style = style(styleID), let context = context(for: style, format: prefs.format) else { return nil }
        return ShareCardRenderer.image(style, context)
    }

    /// A sticker flattened onto its Story background, for apps that are not
    /// Instagram.
    func exportStickerStory(_ styleID: String) -> UIImage? {
        guard let style = style(styleID), style.kind == .sticker, let sticker = exportImage(styleID) else { return nil }
        return StickerStoryRenderer.composite(sticker: sticker, photo: photo, field: prefs.field)
    }
}
