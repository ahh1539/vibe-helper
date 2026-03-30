import SwiftUI
import Charts

struct ModelUsageData: Identifiable {
    let id = UUID()
    let model: String
    let count: Int
    let cost: Double
    let color: Color
}

struct ModelUsageCard: View {
    let sessions: [Session]

    private let palette: [Color] = [.vibePrimary, .vibeAccent, .vibeSuccess, .vibeWarning]

    private var modelData: [ModelUsageData] {
        let grouped = Dictionary(grouping: sessions, by: { $0.activeModelName })
        return grouped
            .map { (model, sessions) in
                (model: model, count: sessions.count, cost: sessions.reduce(0) { $0 + $1.stats.sessionCost })
            }
            .sorted { $0.count > $1.count }
            .enumerated()
            .map { index, item in
                ModelUsageData(
                    model: item.model,
                    count: item.count,
                    cost: item.cost,
                    color: palette[index % palette.count]
                )
            }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Model Usage")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(sessions.count)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.vibePrimary)
                }
                Spacer()
                if modelData.count > 1 {
                    Text("\(modelData.count) models")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !modelData.isEmpty {
                HStack(spacing: 16) {
                    Chart(modelData) { item in
                        SectorMark(
                            angle: .value("Sessions", item.count),
                            innerRadius: .ratio(0.6),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                        .cornerRadius(3)
                    }
                    .frame(height: 120)

                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(modelData) { item in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.model)
                                        .font(.caption.weight(.medium))
                                    Text("\(item.count) sessions · \(String(format: "$%.2f", item.cost))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    Spacer()
                }
            } else {
                Text("No sessions")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .cardStyle()
    }
}
