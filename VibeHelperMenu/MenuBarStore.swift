import Foundation
import SwiftUI

/// Lightweight store for menu bar app
/// Only tracks aggregated stats, not individual sessions
@MainActor
final class MenuBarStore: ObservableObject {
    
    // All loaded sessions
    @Published var sessions: [MenuSession] = []
    
    // Badge type preference
    @AppStorage("menuBarBadgeType") var badgeType: BadgeType = .sessionCount
    
    enum BadgeType: String, CaseIterable {
        case sessionCount = "Sessions"
        case totalCost = "Cost"
        case none = "None"
    }
    
    // Loading state
    @Published var isLoading = false
    
    // Computed stats for Today
    var todayCost: Double {
        sessions.filter { $0.isToday }.reduce(0) { $0 + $1.stats.sessionCost }
    }
    
    var todaySessions: Int {
        sessions.filter { $0.isToday }.count
    }
    
    var todayTokens: Int {
        sessions.filter { $0.isToday }.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens }
    }
    
    // Computed stats for This Week
    var weekCost: Double {
        sessions.filter { $0.isThisWeek }.reduce(0) { $0 + $1.stats.sessionCost }
    }
    
    var weekSessions: Int {
        sessions.filter { $0.isThisWeek }.count
    }
    
    var weekTokens: Int {
        sessions.filter { $0.isThisWeek }.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens }
    }
    
    // Computed stats for All Time
    var totalCost: Double {
        sessions.reduce(0) { $0 + $1.stats.sessionCost }
    }
    
    var totalSessions: Int {
        sessions.count
    }
    
    var totalTokens: Int {
        sessions.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens }
    }
    
    // Check if Vibe is running
    var isVibeRunning: Bool {
        ProcessMonitor.isVibeRunning()
    }
    
    // Badge value based on badgeType
    var badgeValue: String? {
        switch badgeType {
        case .sessionCount:
            return todaySessions > 0 ? "\(todaySessions)" : nil
        case .totalCost:
            return todayCost > 0 ? String(format: "$%.2f", todayCost) : nil
        case .none:
            return nil
        }
    }
    
    // Load sessions
    func load() async {
        isLoading = true
        sessions = await MenuSessionLoader.loadAllSessions()
        isLoading = false
    }
    
    // Refresh sessions
    func refresh() async {
        await load()
    }
    
    // Cycle badge type
    func cycleBadgeType() {
        let allCases = BadgeType.allCases
        let currentIndex = allCases.firstIndex(of: badgeType) ?? 0
        let nextIndex = (currentIndex + 1) % allCases.count
        badgeType = allCases[nextIndex]
    }
}
