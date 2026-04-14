import SwiftUI

@Observable
final class UserSettings {
    static let shared = UserSettings()
    static let suiteName = "group.com.__APP_NAME_LOWER__.shared"
    private let defaults: UserDefaults

    init(defaults: UserDefaults? = nil) {
        self.defaults = defaults ?? UserDefaults(suiteName: UserSettings.suiteName) ?? .standard
    }
}
