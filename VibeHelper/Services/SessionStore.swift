import Foundation
import SwiftUI

@MainActor
final class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []
    @Published var selectedProject: String? = nil
    @Published var timeRange: TimeRange = .allTime
    @Published var isLoading = false
    @Published var selectedSession: Session? = nil

    private var fileWatcher: FileWatcher?

    var filteredSessions: [Session] {
        sessions.filter { session in
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

    func load() async {
        isLoading = true
        sessions = await SessionLoader.loadAllSessions()
        isLoading = false
    }

    func startWatching() {
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
}
