import Foundation

/// What the share screen remembers between visits.
struct ShareStudioPrefs: Codable, Equatable, Sendable {
    var styleID: String?
    var format: ShareCardFormat = .story
    var field: ShareCardField = .indigo
    /// Keyed by style id.
    var values: [String: ShareCardOptionValues] = [:]

    init() {}

    init(from decoder: Decoder) throws {
        // Every key is optional, so an older or newer blob still loads.
        let container = try decoder.container(keyedBy: CodingKeys.self)
        styleID = try container.decodeIfPresent(String.self, forKey: .styleID)
        format = (try? container.decodeIfPresent(ShareCardFormat.self, forKey: .format)) ?? .story
        field = (try? container.decodeIfPresent(ShareCardField.self, forKey: .field)) ?? .indigo
        values = (try? container.decodeIfPresent([String: ShareCardOptionValues].self, forKey: .values)) ?? [:]
    }

    static func load(from settings: UserSettings) -> ShareStudioPrefs {
        guard let data = settings.shareStudioPrefsData,
              let prefs = try? JSONDecoder().decode(ShareStudioPrefs.self, from: data) else { return ShareStudioPrefs() }
        return prefs
    }

    func save(to settings: UserSettings) {
        settings.shareStudioPrefsData = try? JSONEncoder().encode(self)
    }

    /// Drops choices that belong to one class before they are stored.
    func persistable(using options: (String) -> [ShareCardOption]) -> ShareStudioPrefs {
        var copy = self
        for (styleID, var values) in copy.values {
            for option in options(styleID) where !option.persists {
                values.choices[option.id] = nil
                values.toggles[option.id] = nil
            }
            copy.values[styleID] = values
        }
        return copy
    }
}
