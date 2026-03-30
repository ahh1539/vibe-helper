import SwiftUI
import Charts

struct CostCard: View {
    let sessions: [Session]

    @State private var selectedModel: String? = nil

    private var models: [String] {
        Array(Set(sessions.map { $0.activeModelName })).sorted()
    }

    private var filteredSessions: [Session] {
        guard let model = selectedModel else { return sessions }
        return sessions.filter { $0.activeModelName == model }
    }

    private var totalCost: Double {
        filteredSessions.reduce(0) { $0 + $1.stats.sessionCost }
    }

    private var cumulativeCosts: [(date: Date, cost: Double)] {
        var running = 0.0
        return filteredSessions
            .sorted { $0.startTime < $1.startTime }
            .map { session in
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
                    Text("\(filteredSessions.count) sessions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !filteredSessions.isEmpty {
                        Text("avg \(String(format: "$%.2f", totalCost / Double(filteredSessions.count)))/session")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if models.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ModelPill(label: "All", isSelected: selectedModel == nil) {
                            selectedModel = nil
                        }
                        ForEach(models, id: \.self) { model in
                            ModelPill(label: model, isSelected: selectedModel == model) {
                                selectedModel = selectedModel == model ? nil : model
                            }
                        }
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
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardStyle()
    }
}

private struct ModelPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.vibePrimary.opacity(0.15) : Color.primary.opacity(0.05))
                .foregroundStyle(isSelected ? Color.vibePrimary : Color.secondary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.vibePrimary.opacity(0.4) : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
