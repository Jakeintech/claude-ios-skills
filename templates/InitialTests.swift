import Testing
@testable import __APP_NAME__

struct __APP_NAME__Tests {
    @Test(.tags(.model))
    func appStateInitializes() {
        let settings = UserSettings(defaults: UserDefaults(suiteName: nil))
        let state = AppState(settings: settings)
        #expect(state.settings === settings)
    }
}

extension Tag {
    @Tag static var model: Self
    @Tag static var service: Self
    @Tag static var view: Self
}
