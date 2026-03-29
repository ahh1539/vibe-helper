import Foundation

enum TimeRange: Equatable {
    case today
    case week
    case month
    case allTime
    case custom(Date, Date)

    var label: String {
        switch self {
        case .today: return "Today"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .allTime: return "All Time"
        case .custom: return "Custom"
        }
    }

    var startDate: Date? {
        let calendar = Calendar.current
        switch self {
        case .today:
            return calendar.startOfDay(for: Date())
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        case .allTime:
            return nil
        case .custom(let start, _):
            return start
        }
    }

    var endDate: Date? {
        switch self {
        case .custom(_, let end):
            return end
        default:
            return nil
        }
    }
}
