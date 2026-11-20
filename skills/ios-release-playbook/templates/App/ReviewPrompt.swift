import StoreKit
import SwiftUI

// App Store rating prompt, asked once at a key moment.
//
// Wiring (see SKILL.md §1.7):
// 1. `AppState` owns one `ReviewPrompter(mode: launchOptions.reviewPrompt)`.
// 2. Call `recordSession()` once per launch, and `recordFriction()` after an error, a failed load or a purchase.
// 3. Call `recordKeyMoment()` at the app's high-signal moment: an island, level or run won; the Nth
//    successful core action. Never on launch, mid-task, after an error or right after a purchase.
// 4. Put `.reviewPrompt(appState.reviewPrompter)` on the root view. It asks the system 1.5 s later,
//    once the win screen has settled.
// 5. Settings or About gets `RateAppRow(appName:appStoreID:)` for people who want to rate on their own.
//
// The system shows the prompt at most 3 times in 365 days and may not show it at all (it never shows
// on TestFlight). Never put a custom "Do you like this app?" screen in front of it that sends happy
// people to the App Store and unhappy people elsewhere: App Review guideline 5.6.1 rejects that.

// MARK: - Policy (pure; tested by ReviewPromptPolicyTests)

/// What the app remembers about rating prompts. `ReviewPromptStore` keeps it in UserDefaults.
struct ReviewPromptState: Sendable, Equatable, Codable {
    var firstLaunch: Date
    var sessionCount = 0
    var successCount = 0
    var lastFrictionDate: Date?
    var lastPromptDate: Date?
    var lastPromptVersion: String?
}

/// The gates that must all pass before the app asks the system for a review.
struct ReviewPromptPolicy: Sendable, Equatable {
    /// App launches before the first ask.
    var minSessions = 3
    /// Key moments (wins, completed goals) before the first ask.
    var minSuccesses = 3
    /// Days since the first launch before the first ask.
    var minDaysSinceInstall = 3
    /// Days between asks. 120 keeps the app under Apple's 3-a-year cap without wasting an ask.
    var minDaysBetweenPrompts = 120
    /// Hours of quiet after an error, a failed load or a purchase.
    var quietHoursAfterFriction = 24

    func shouldRequest(_ state: ReviewPromptState, appVersion: String, now: Date) -> Bool {
        guard state.sessionCount >= minSessions, state.successCount >= minSuccesses else { return false }
        guard now.timeIntervalSince(state.firstLaunch) >= Self.days(minDaysSinceInstall) else { return false }
        if state.lastPromptVersion == appVersion { return false }
        if let last = state.lastPromptDate, now.timeIntervalSince(last) < Self.days(minDaysBetweenPrompts) {
            return false
        }
        if let friction = state.lastFrictionDate,
           now.timeIntervalSince(friction) < TimeInterval(quietHoursAfterFriction) * 3_600 {
            return false
        }
        return true
    }

    private static func days(_ n: Int) -> TimeInterval { TimeInterval(n) * 86_400 }
}

// MARK: - Launch-argument mode

/// `-reviewPrompt force|off`. Demo mode (`-demo 1`) suppresses the prompt unless `force` is passed, so it
/// can never land in an App Store screenshot. `force` skips the gates so the wiring can be checked in a
/// Debug build (the simulator and Xcode builds always show the sheet; TestFlight never does).
enum ReviewPromptMode: String, Sendable, Equatable {
    case normal
    case forced
    case suppressed

    init(arguments: [String] = ProcessInfo.processInfo.arguments, isDemo: Bool) {
        let value = arguments.firstIndex(of: "-reviewPrompt").flatMap { i in
            i + 1 < arguments.count ? arguments[i + 1] : nil
        }
        switch value {
        case "off", "0", "NO": self = .suppressed
        case "force", "1", "YES": self = .forced
        default: self = isDemo ? .suppressed : .normal
        }
    }
}

// MARK: - Storage

/// Reads and writes `ReviewPromptState` as one JSON value in UserDefaults.
struct ReviewPromptStore {
    var defaults: UserDefaults = .standard
    var key = "reviewPrompt.state"

    func load() -> ReviewPromptState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(ReviewPromptState.self, from: data)
    }

    func save(_ state: ReviewPromptState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}

// MARK: - Prompter

@MainActor
@Observable
final class ReviewPrompter {
    /// True once a key moment passed the policy; `.reviewPrompt(_:)` then asks the system.
    private(set) var isRequestPending = false
    let mode: ReviewPromptMode

    @ObservationIgnored private let policy: ReviewPromptPolicy
    @ObservationIgnored private let store: ReviewPromptStore
    @ObservationIgnored private let appVersion: String
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private(set) var state: ReviewPromptState

    init(
        mode: ReviewPromptMode,
        policy: ReviewPromptPolicy = ReviewPromptPolicy(),
        store: ReviewPromptStore = ReviewPromptStore(),
        appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0",
        now: @escaping () -> Date = { Date() }
    ) {
        self.mode = mode
        self.policy = policy
        self.store = store
        self.appVersion = appVersion
        self.now = now
        self.state = store.load() ?? ReviewPromptState(firstLaunch: now())
    }

    /// Once per launch.
    func recordSession() {
        guard mode != .suppressed else { return }
        state.sessionCount += 1
        store.save(state)
    }

    /// After an error, a failed load or a purchase: no ask for `quietHoursAfterFriction`.
    func recordFriction() {
        guard mode != .suppressed else { return }
        state.lastFrictionDate = now()
        store.save(state)
    }

    /// At the app's high-signal moment. Asks only when every gate passes (or in `.forced` mode).
    func recordKeyMoment() {
        switch mode {
        case .suppressed:
            return
        case .forced:
            isRequestPending = true
        case .normal:
            state.successCount += 1
            store.save(state)
            if policy.shouldRequest(state, appVersion: appVersion, now: now()) {
                isRequestPending = true
            }
        }
    }

    /// Called by `.reviewPrompt(_:)` after it asks the system. Whether the sheet showed is unknowable,
    /// so an ask counts as used.
    func didRequestReview() {
        isRequestPending = false
        guard mode == .normal else { return }
        state.lastPromptDate = now()
        state.lastPromptVersion = appVersion
        store.save(state)
    }
}

// MARK: - SwiftUI

extension View {
    /// Put on the root view. Asks the system for a review when `prompter` has a pending request.
    func reviewPrompt(_ prompter: ReviewPrompter) -> some View {
        modifier(ReviewPromptModifier(prompter: prompter))
    }
}

private struct ReviewPromptModifier: ViewModifier {
    let prompter: ReviewPrompter
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content.task(id: prompter.isRequestPending && scenePhase == .active) {
            guard prompter.isRequestPending, scenePhase == .active else { return }
            // Let the win screen land before the system sheet slides up.
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled, prompter.isRequestPending else { return }
            requestReview()
            prompter.didRequestReview()
        }
    }
}

enum AppStoreLinks {
    /// Opens the app's product page on the "Write a Review" sheet. Works once the app is live.
    static func writeReview(appStoreID: String) -> URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}

/// A "Rate MyApp" row for Settings or About. `appStoreID` is the ASC app id (`app-info.json` › `app_id`).
struct RateAppRow: View {
    let appName: String
    let appStoreID: String

    var body: some View {
        if let url = AppStoreLinks.writeReview(appStoreID: appStoreID) {
            Link(destination: url) {
                Label("Rate \(appName)", systemImage: "star")
            }
            .accessibilityHint("Opens the App Store to write a review")
        }
    }
}
