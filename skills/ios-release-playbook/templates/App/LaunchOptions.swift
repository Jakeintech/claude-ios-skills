import Foundation

/// Launch arguments: `-demo 1 -now 2026-11-11T20:46:00Z`, plus `-state <name>`, `-tab <name>`,
/// `-redNight 1` and `-screen <name>` for checking designed states in the simulator. Demo only:
/// `-layers a,b` turns map layers on, `-pro 1` unlocks Pro and `-minute <ISO>` sets the Plan
/// minute, to check and capture the layers.
struct LaunchOptions: Sendable, Equatable {
    var isDemo = false
    var now: Date?
    var forcedState: String?
    var initialTab: String?
    var redNight: Bool?
    var screen: String?
    var skipOnboarding = true
    /// `-layers a,b` in demo mode: switch map layers on for screenshots.
    var layers: [String] = []
    /// `-pro 1` in demo mode: unlock Pro to check Pro screens. Ignored outside demo mode.
    var previewPro = false
    /// `-minute 2026-11-24T20:23:00Z` in demo mode: a chosen time on one screen. Ignored outside demo mode.
    var minute: Date?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(_ key: String) -> String? {
            guard let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
            return arguments[i + 1]
        }
        isDemo = value("-demo") == "1" || value("-demo") == "YES"
        if let s = value("-now") {
            now = ISO8601DateFormatter().date(from: s)
        } else if isDemo {
            now = DemoScenario.canvasNow
        }
        forcedState = value("-state")
        initialTab = value("-tab")
        if let r = value("-redNight") { redNight = r == "1" || r == "YES" }
        screen = value("-screen")
        if let o = value("-onboarding") { skipOnboarding = !(o == "1" || o == "YES") }
        layers = value("-layers")?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
        previewPro = isDemo && (value("-pro") == "1" || value("-pro") == "YES")
        if isDemo, let m = value("-minute") { minute = ISO8601DateFormatter().date(from: m) }
    }
}
