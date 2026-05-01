import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published var sessions: [Session] = [] {
        didSet {
            // Invalidate all cached filtered arrays when sessions change
            _cachedSessionsToday = nil
            _cachedSessionsThisWeek = nil
            _cachedSessionsThisMonth = nil
            _cachedFilteredSessions = nil
        }
    }
    @Published var selectedProject: String? = nil {
        didSet {
            // Invalidate filteredSessions cache when project filter changes
            _cachedFilteredSessions = nil
        }
    }
    @Published var timeRange: TimeRange = .week {
        didSet {
            // Invalidate filteredSessions cache when time range changes
            _cachedFilteredSessions = nil
        }
    }
    @Published var isLoading = false
    @Published var menuBarTimeRange: TimeRange = .today

    @Published var menuBarRefreshInterval: Int = UserDefaults.standard.integer(forKey: "menuBarRefreshInterval") {
        didSet {
            UserDefaults.standard.set(menuBarRefreshInterval, forKey: "menuBarRefreshInterval")
            rescheduleRefreshTimer()
        }
    }

    @Published var nextRefreshAt: Date?
    @Published var lastRefreshedAt: Date?

    private var fileWatcher: FileWatcher?
    private var refreshTimer: Timer?

    // MARK: - Cached filtered arrays

    private var _cachedSessionsToday: [Session]? = nil
    private var _cachedSessionsThisWeek: [Session]? = nil
    private var _cachedSessionsThisMonth: [Session]? = nil
    private var _cachedFilteredSessions: [Session]? = nil

    private func getSessionsToday() -> [Session] {
        if let cached = _cachedSessionsToday { return cached }
        let result = sessions.filter { Calendar.current.isDateInToday($0.startTime) }
        _cachedSessionsToday = result
        return result
    }

    private func getSessionsThisWeek() -> [Session] {
        if let cached = _cachedSessionsThisWeek { return cached }
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -7, to: Date()) else { return [] }
        let result = sessions.filter { $0.startTime >= start }
        _cachedSessionsThisWeek = result
        return result
    }

    private func getSessionsThisMonth() -> [Session] {
        if let cached = _cachedSessionsThisMonth { return cached }
        let calendar = Calendar.current
        guard let start = calendar.date(byAdding: .day, value: -30, to: Date()) else { return [] }
        let result = sessions.filter { $0.startTime >= start }
        _cachedSessionsThisMonth = result
        return result
    }

    var filteredSessions: [Session] {
        if let cached = _cachedFilteredSessions { return cached }
        let result = sessions.filter { session in
            let matchesProject = selectedProject == nil || session.projectName == selectedProject
            let matchesTime: Bool
            if let start = timeRange.startDate {
                let end = timeRange.endDate ?? Date()
                matchesTime = session.startTime >= start && session.startTime <= end
            } else {
                matchesTime = true
            }
            return matchesProject && matchesTime
        }
        _cachedFilteredSessions = result
        return result
    }

    var projects: [String] {
        Array(Set(sessions.map(\.projectName))).sorted()
    }

    var totalCost: Double {
        filteredSessions.reduce(0) { $0 + $1.stats.sessionCost }
    }

    var totalTokens: Int {
        filteredSessions.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens }
    }

    var totalSessions: Int {
        filteredSessions.count
    }

    var totalToolCalls: Int {
        filteredSessions.reduce(0) { $0 + $1.stats.totalToolCalls }
    }

    var averageTokensPerSecond: Double {
        let speeds = filteredSessions.map(\.stats.tokensPerSecond)
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    var costByProject: [(project: String, cost: Double)] {
        Dictionary(grouping: filteredSessions, by: \.projectName)
            .map { (project: $0.key, cost: $0.value.reduce(0) { $0 + $1.stats.sessionCost }) }
            .sorted { $0.cost > $1.cost }
    }

    var toolCallBreakdown: (agreed: Int, rejected: Int, failed: Int) {
        let agreed = filteredSessions.reduce(0) { $0 + $1.stats.toolCallsAgreed }
        let rejected = filteredSessions.reduce(0) { $0 + $1.stats.toolCallsRejected }
        let failed = filteredSessions.reduce(0) { $0 + $1.stats.toolCallsFailed }
        return (agreed, rejected, failed)
    }

    // MARK: - Menu bar stats (read-only, don't mutate shared filter state)

    var costToday: Double { getSessionsToday().reduce(0) { $0 + $1.stats.sessionCost } }
    var costThisWeek: Double { getSessionsThisWeek().reduce(0) { $0 + $1.stats.sessionCost } }
    var costThisMonth: Double { getSessionsThisMonth().reduce(0) { $0 + $1.stats.sessionCost } }
    var costAllTime: Double { sessions.reduce(0) { $0 + $1.stats.sessionCost } }

    var sessionsToday: Int { getSessionsToday().count }
    var sessionsThisWeek: Int { getSessionsThisWeek().count }
    var sessionsThisMonth: Int { getSessionsThisMonth().count }
    var sessionsAllTime: Int { sessions.count }

    var tokensToday: Int { getSessionsToday().reduce(0) { $0 + $1.stats.sessionTotalLlmTokens } }
    var tokensThisWeek: Int { getSessionsThisWeek().reduce(0) { $0 + $1.stats.sessionTotalLlmTokens } }
    var tokensThisMonth: Int { getSessionsThisMonth().reduce(0) { $0 + $1.stats.sessionTotalLlmTokens } }
    var tokensAllTime: Int { sessions.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens } }

    // MARK: - Tokens per second averages for menu bar

    var tokensPerSecondToday: Double {
        let today = getSessionsToday()
        guard !today.isEmpty else { return 0 }
        return today.reduce(0) { $0 + $1.stats.tokensPerSecond } / Double(today.count)
    }

    var tokensPerSecondThisWeek: Double {
        let week = getSessionsThisWeek()
        guard !week.isEmpty else { return 0 }
        return week.reduce(0) { $0 + $1.stats.tokensPerSecond } / Double(week.count)
    }

    var tokensPerSecondThisMonth: Double {
        let month = getSessionsThisMonth()
        guard !month.isEmpty else { return 0 }
        return month.reduce(0) { $0 + $1.stats.tokensPerSecond } / Double(month.count)
    }

    func load() async {
        isLoading = true
        sessions = await SessionLoader.loadAllSessions()
        isLoading = false
        lastRefreshedAt = Date()
    }

    func startWatching() {
        guard fileWatcher == nil else { return }
        let path = SessionLoader.sessionDirectory.path
        fileWatcher = FileWatcher(path: path) { [weak self] in
            Task { @MainActor in
                await self?.load()
            }
        }
        fileWatcher?.start()
    }

    func stopWatching() {
        fileWatcher?.stop()
    }

    // MARK: - Menu bar auto refresh

    func startRefreshTimerIfNeeded() {
        rescheduleRefreshTimer()
    }

    func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        nextRefreshAt = nil
    }

    // MARK: - Cleanup

    /// Clean up resources. Can be called manually if needed.
    @MainActor
    func cleanup() {
        stopWatching()
        stopRefreshTimer()
    }

    private func rescheduleRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        nextRefreshAt = nil

        let minutes = menuBarRefreshInterval
        guard minutes > 0 else { return }

        let interval = TimeInterval(minutes * 60)
        nextRefreshAt = Date().addingTimeInterval(interval)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                Task {
                    await self?.load()
                    self?.nextRefreshAt = Date().addingTimeInterval(interval)
                }
            }
        }
    }
}
