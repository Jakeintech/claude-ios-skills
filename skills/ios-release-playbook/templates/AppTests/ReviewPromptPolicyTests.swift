import Foundation
import Testing
@testable import MyApp

extension Tag {
    @Tag static var reviewPrompt: Self
}

@Suite(.tags(.reviewPrompt))
struct ReviewPromptPolicyTests {
    let install = Date(timeIntervalSince1970: 1_800_000_000)
    let policy = ReviewPromptPolicy()

    func day(_ n: Double) -> Date { install.addingTimeInterval(n * 86_400) }

    /// A state that passes every gate on day 10.
    var ready: ReviewPromptState {
        ReviewPromptState(firstLaunch: install, sessionCount: 3, successCount: 3)
    }

    @Test func testShouldRequest_allGatesPass_returnsTrue() {
        #expect(policy.shouldRequest(ready, appVersion: "1.0.0", now: day(10)))
    }

    @Test func testShouldRequest_tooFewSuccesses_returnsFalse() {
        var state = ready
        state.successCount = 2
        #expect(!policy.shouldRequest(state, appVersion: "1.0.0", now: day(10)))
    }

    @Test func testShouldRequest_tooFewSessions_returnsFalse() {
        var state = ready
        state.sessionCount = 2
        #expect(!policy.shouldRequest(state, appVersion: "1.0.0", now: day(10)))
    }

    @Test func testShouldRequest_tooSoonAfterInstall_returnsFalse() {
        #expect(!policy.shouldRequest(ready, appVersion: "1.0.0", now: day(2.9)))
        #expect(policy.shouldRequest(ready, appVersion: "1.0.0", now: day(3)))
    }

    @Test func testShouldRequest_alreadyAskedThisVersion_returnsFalse() {
        var state = ready
        state.lastPromptDate = day(-400)
        state.lastPromptVersion = "1.0.0"
        #expect(!policy.shouldRequest(state, appVersion: "1.0.0", now: day(10)))
    }

    @Test func testShouldRequest_newVersionTooSoonAfterLastAsk_returnsFalse() {
        var state = ready
        state.lastPromptDate = day(10)
        state.lastPromptVersion = "1.0.0"
        #expect(!policy.shouldRequest(state, appVersion: "1.1.0", now: day(129)))
        #expect(policy.shouldRequest(state, appVersion: "1.1.0", now: day(130)))
    }

    @Test func testShouldRequest_recentFriction_returnsFalse() {
        var state = ready
        state.lastFrictionDate = day(10).addingTimeInterval(-3_600)
        #expect(!policy.shouldRequest(state, appVersion: "1.0.0", now: day(10)))
        state.lastFrictionDate = day(9)
        #expect(policy.shouldRequest(state, appVersion: "1.0.0", now: day(10)))
    }
}

@Suite(.tags(.reviewPrompt))
struct ReviewPromptModeTests {
    @Test func testInit_demoWithoutFlag_suppressed() {
        #expect(ReviewPromptMode(arguments: ["-demo", "1"], isDemo: true) == .suppressed)
    }

    @Test func testInit_noFlags_normal() {
        #expect(ReviewPromptMode(arguments: [], isDemo: false) == .normal)
    }

    @Test func testInit_forceInDemo_forced() {
        #expect(ReviewPromptMode(arguments: ["-reviewPrompt", "force"], isDemo: true) == .forced)
    }

    @Test func testInit_off_suppressed() {
        #expect(ReviewPromptMode(arguments: ["-reviewPrompt", "off"], isDemo: false) == .suppressed)
    }
}

@MainActor
@Suite(.tags(.reviewPrompt))
struct ReviewPrompterTests {
    final class Clock { var now = Date(timeIntervalSince1970: 1_800_000_000) }

    func makeStore() -> ReviewPromptStore {
        ReviewPromptStore(defaults: UserDefaults(suiteName: "ReviewPrompterTests.\(UUID().uuidString)")!)
    }

    @Test func testRecordKeyMoment_gatesPassOnThirdWin_requestsOnceThisVersion() {
        let clock = Clock()
        let store = makeStore()
        let prompter = ReviewPrompter(mode: .normal, store: store, appVersion: "1.0.0", now: { clock.now })
        for _ in 0..<3 { prompter.recordSession() }
        clock.now = clock.now.addingTimeInterval(4 * 86_400)

        prompter.recordKeyMoment()
        prompter.recordKeyMoment()
        #expect(!prompter.isRequestPending)
        prompter.recordKeyMoment()
        #expect(prompter.isRequestPending)

        prompter.didRequestReview()
        #expect(store.load()?.lastPromptVersion == "1.0.0")
        prompter.recordKeyMoment()
        #expect(!prompter.isRequestPending)
    }

    @Test func testRecordKeyMoment_suppressed_neverRequestsOrWrites() {
        let store = makeStore()
        let prompter = ReviewPrompter(mode: .suppressed, store: store, appVersion: "1.0.0")
        for _ in 0..<10 {
            prompter.recordSession()
            prompter.recordKeyMoment()
        }
        #expect(!prompter.isRequestPending)
        #expect(store.load() == nil)
    }

    @Test func testRecordKeyMoment_forced_requestsOnFirstMoment() {
        let prompter = ReviewPrompter(mode: .forced, store: makeStore(), appVersion: "1.0.0")
        prompter.recordKeyMoment()
        #expect(prompter.isRequestPending)
    }

    @Test func testRecordKeyMoment_afterFriction_waitsForQuietPeriod() {
        let clock = Clock()
        let prompter = ReviewPrompter(mode: .normal, store: makeStore(), appVersion: "1.0.0", now: { clock.now })
        for _ in 0..<3 { prompter.recordSession() }
        clock.now = clock.now.addingTimeInterval(4 * 86_400)
        prompter.recordKeyMoment()
        prompter.recordKeyMoment()
        prompter.recordFriction()
        prompter.recordKeyMoment()
        #expect(!prompter.isRequestPending)
        clock.now = clock.now.addingTimeInterval(25 * 3_600)
        prompter.recordKeyMoment()
        #expect(prompter.isRequestPending)
    }
}
