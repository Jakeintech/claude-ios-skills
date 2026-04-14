import SwiftUI

@Observable
@MainActor
final class AppState {
    let settings: UserSettings

    init(settings: UserSettings = .shared) {
        self.settings = settings
    }
}
