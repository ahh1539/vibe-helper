import SwiftUI
import Charts

struct ActivityCard: View {
    let sessions: [Session]

    private var sessionsByDay: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }
        return grouped
            .map { (date: $0.key, count: $0.value.count) }
            .sorted { $0.date < $1.date }
    }

    private var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    private var avgDuration: TimeInterval {
        guard !sessions.isEmpty else { return 0 }
        return totalDuration / Double(sessions.count)
    }

    private var heatmapWeeks: [[DayCell]] {
        let calendar = Calendar.current
        guard let earliest = sessions.map(\.startTime).min(),
              let latest = sessions.map(\.startTime).max() else { return [] }

        let start = calendar.startOfDay(for: earliest)
        let end = calendar.startOfDay(for: latest)
        let countByDay = Dictionary(grouping: sessions) { session in
            calendar.startOfDay(for: session.startTime)
        }.mapValues(\.count)

        var cells: [DayCell] = []
        var current = start
        while current <= end {
            cells.append(DayCell(date: current, count: countByDay[current] ?? 0))
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }

        // Pad start to Sunday
        let startWeekday = calendar.component(.weekday, from: start)
        let padding = startWeekday - 1
        let paddedCells = Array(repeating: DayCell(date: .distantPast, count: -1), count: padding) + cells

        return stride(from: 0, to: paddedCells.count, by: 7).map { i in
            Array(paddedCells[i..<min(i + 7, paddedCells.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Activity")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(sessions.count) sessions")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.vibeSuccess)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("avg \(formatDuration(avgDuration))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("total \(formatDuration(totalDuration))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Heatmap
            if !heatmapWeeks.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(Array(heatmapWeeks.enumerated()), id: \.offset) { _, week in
                            VStack(spacing: 3) {
                                ForEach(Array(week.enumerated()), id: \.offset) { _, cell in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(cell.count < 0 ? Color.clear : colorForCount(cell.count))
                                        .frame(width: 14, height: 14)
                                        .help(cell.count >= 0 ? "\(cell.date.dayFormatted): \(cell.count) sessions" : "")
                                }
                                // Pad remaining days in the week
                                ForEach(0..<max(0, 7 - week.count), id: \.self) { _ in
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.clear)
                                        .frame(width: 14, height: 14)
                                }
                            }
                        }
                    }
                }
                .frame(height: 120)
            }
        }
        .cardStyle()
    }

    private func colorForCount(_ count: Int) -> Color {
        switch count {
        case 0: return Color.vibeSuccess.opacity(0.08)
        case 1: return Color.vibeSuccess.opacity(0.3)
        case 2...3: return Color.vibeSuccess.opacity(0.5)
        case 4...6: return Color.vibeSuccess.opacity(0.7)
        default: return Color.vibeSuccess
        }
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

private struct DayCell {
    let date: Date
    let count: Int
}
