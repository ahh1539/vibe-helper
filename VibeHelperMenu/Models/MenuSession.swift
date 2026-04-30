import Foundation

/// Minimal session model for menu bar app - only includes essential fields
struct MenuSession: Codable, Identifiable {
    let sessionId: String
    let startTime: Date
    let stats: MenuSessionStats
    
    var id: String { sessionId }
    
    var date: Date { startTime }
}

struct MenuSessionStats: Codable {
    let sessionCost: Double
    let sessionTotalLlmTokens: Int
}

// For filtering sessions by date
extension MenuSession {
    var isToday: Bool {
        Calendar.current.isDate(startTime, inSameDayAs: Date())
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(startTime, inSameWeekAs: Date())
    }
    
    var isInLast7Days: Bool {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        return startTime >= sevenDaysAgo
    }
}
