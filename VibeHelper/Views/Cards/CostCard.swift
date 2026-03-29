import SwiftUI
import Charts

struct CostCard: View {
    let sessions: [Session]

    private var sortedSessions: [Session] {
        sessions.sorted { $0.startTime < $1.startTime }
    }

    private var totalCost: Double {
        sessions.reduce(0) { $0 + $1.stats.sessionCost }
    }

    private var cumulativeCosts: [(date: Date, cost: Double)] {
        var running = 0.0
        return sortedSessions.map { session in
            running += session.stats.sessionCost
            return (date: session.startTime, cost: running)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Spend")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(String(format: "$%.2f", totalCost))
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.vibePrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(sessions.count) sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !sessions.isEmpty {
                        Text("avg \(String(format: "$%.2f", totalCost / Double(sessions.count)))/session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !cumulativeCosts.isEmpty {
                Chart(cumulativeCosts, id: \.date) { item in
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Cost", item.cost)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.vibePrimary.opacity(0.3), Color.vibePrimary.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Cost", item.cost)
                    )
                    .foregroundStyle(Color.vibePrimary)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let cost = value.as(Double.self) {
                                Text(String(format: "$%.2f", cost))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let date = value.as(Date.self) {
                                Text(date.dayFormatted)
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 140)
            }
        }
        .cardStyle()
    }
}
