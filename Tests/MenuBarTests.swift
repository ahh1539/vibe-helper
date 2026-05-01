import XCTest
@testable import VibeHelper

@MainActor
final class MenuBarTests: XCTestCase {

    // MARK: - VibeProcessMonitor Tests

    func testProcessMonitorInitialState() {
        let monitor = VibeProcessMonitor()
        // Verify the property exists and is accessible
        _ = monitor.isRunning
    }

    // MARK: - SessionStore Menu Bar Stats Tests

    func testSessionStoreMenuBarStatsEmpty() {
        let store = SessionStore()
        store.sessions = []

        XCTAssertEqual(store.costToday, 0)
        XCTAssertEqual(store.sessionsToday, 0)
        XCTAssertEqual(store.tokensToday, 0)
        XCTAssertEqual(store.tokensPerSecondToday, 0)

        XCTAssertEqual(store.costThisWeek, 0)
        XCTAssertEqual(store.sessionsThisWeek, 0)
        XCTAssertEqual(store.tokensThisWeek, 0)

        XCTAssertEqual(store.costThisMonth, 0)
        XCTAssertEqual(store.sessionsThisMonth, 0)
        XCTAssertEqual(store.tokensThisMonth, 0)

        XCTAssertEqual(store.costAllTime, 0)
        XCTAssertEqual(store.sessionsAllTime, 0)
    }

    func testSessionStoreMenuBarStatsWithData() {
        let store = SessionStore()
        let calendar = Calendar.current
        let now = Date()

        // Create sessions with known dates
        let todaySession = makeTestSession(startTime: now, cost: 0.001, tokens: 300, tps: 10.0)
        let yesterdaySession = makeTestSession(
            startTime: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            cost: 0.0005,
            tokens: 150,
            tps: 20.0
        )

        store.sessions = [todaySession, yesterdaySession]

        // Test today stats
        XCTAssertEqual(store.sessionsToday, 1)
        XCTAssertEqual(store.costToday, 0.001, accuracy: 0.0001)
        XCTAssertEqual(store.tokensToday, 300)

        // Test week stats (both should be within a week)
        XCTAssertGreaterThanOrEqual(store.sessionsThisWeek, 1)
        XCTAssertGreaterThanOrEqual(store.costThisWeek, 0.0009)

        // Test all time
        XCTAssertEqual(store.sessionsAllTime, 2)
        XCTAssertEqual(store.costAllTime, 0.0015, accuracy: 0.0001)
        XCTAssertEqual(store.tokensAllTime, 450)
    }

    func testSessionStoreCaching() {
        let store = SessionStore()
        let session1 = makeTestSession(startTime: Date(), cost: 0.001, tokens: 100, tps: 5.0)
        let session2 = makeTestSession(startTime: Date(), cost: 0.002, tokens: 200, tps: 10.0)

        store.sessions = [session1, session2]

        // Access cached properties multiple times
        let cost1 = store.costToday
        let cost2 = store.costToday

        // Should return same cached result
        XCTAssertEqual(cost1, cost2)

        // Invalidate cache by setting new sessions
        store.sessions = [session1]

        // Cache should be invalidated
        let cost3 = store.costToday
        XCTAssertNotEqual(cost2, cost3)
    }

    // MARK: - TimeRange Tests

    func testTimeRangeStartDates() {
        let calendar = Calendar.current
        let now = Date()

        // Test today
        let today = TimeRange.today
        let todayStart = today.startDate
        XCTAssertNotNil(todayStart)
        if let todayStart {
            XCTAssertTrue(calendar.isDateInToday(todayStart))
        }

        // Test week
        let week = TimeRange.week
        let weekStart = week.startDate
        XCTAssertNotNil(weekStart)
        if let weekStart {
            let daysDiff = calendar.dateComponents([.day], from: weekStart, to: now).day ?? 0
            XCTAssertGreaterThanOrEqual(daysDiff, 0)
            XCTAssertLessThanOrEqual(daysDiff, 7)
        }

        // Test month
        let month = TimeRange.month
        let monthStart = month.startDate
        XCTAssertNotNil(monthStart)
        if let monthStart {
            let daysDiff = calendar.dateComponents([.day], from: monthStart, to: now).day ?? 0
            XCTAssertGreaterThanOrEqual(daysDiff, 0)
            XCTAssertLessThanOrEqual(daysDiff, 30)
        }
    }

    // MARK: - StoresContainer Tests

    func testStoresContainerSingleton() {
        let container1 = StoresContainer.shared
        let container2 = StoresContainer.shared
        XCTAssertTrue(container1 === container2)
    }

    func testStoresContainerLazyInitialization() {
        let container = StoresContainer.shared
        _ = container.sessionStore
        _ = container.skillStore
        _ = container.configStore
        _ = container.processMonitor

        // Verify stores are initialized
        XCTAssertNotNil(container.sessionStore)
        XCTAssertNotNil(container.skillStore)
        XCTAssertNotNil(container.configStore)
        XCTAssertNotNil(container.processMonitor)
    }

    // MARK: - Helper

    private func makeTestSession(
        startTime: Date,
        cost: Double,
        tokens: Int,
        tps: Double
    ) -> Session {
        Session(
            sessionId: UUID().uuidString,
            startTime: startTime,
            endTime: startTime,
            gitCommit: nil,
            gitBranch: nil,
            environment: SessionEnvironment(workingDirectory: "/test"),
            username: "test",
            stats: SessionStats(
                steps: 1,
                sessionPromptTokens: tokens / 2,
                sessionCompletionTokens: tokens / 2,
                toolCallsAgreed: 0,
                toolCallsRejected: 0,
                toolCallsFailed: 0,
                toolCallsSucceeded: 0,
                contextTokens: 100,
                lastTurnPromptTokens: 10,
                lastTurnCompletionTokens: 10,
                lastTurnDuration: 1.0,
                tokensPerSecond: tps,
                inputPricePerMillion: 0.5,
                outputPricePerMillion: 1.5,
                sessionTotalLlmTokens: tokens,
                lastTurnTotalTokens: 20,
                sessionCost: cost
            ),
            title: "Test Session",
            totalMessages: 1,
            config: nil,
            agentProfile: nil,
            directoryURL: nil
        )
    }
}
