import SwiftUI
import Charts

struct TokenDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let value: Int
}

struct TokenCard: View {
    let sessions: [Session]

    private var totalTokens: Int {
        sessions.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens }
    }

    private var avgTokensPerSecond: Double {
        let speeds = sessions.map(\.stats.tokensPerSecond)
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    private var tokenData: [TokenDataPoint] {
        let sorted = sessions.sorted { $0.startTime < $1.startTime }
        return sorted.flatMap { session -> [TokenDataPoint] in
            [
                TokenDataPoint(date: session.startTime, label: "Input", value: session.stats.sessionPromptTokens),
                TokenDataPoint(date: session.startTime, label: "Output", value: session.stats.sessionCompletionTokens),
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Tokens")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(totalTokens.formattedTokenCount)
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.vibeAccent)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.0f tok/s avg", avgTokensPerSecond))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    let totalInput = sessions.reduce(0) { $0 + $1.stats.sessionPromptTokens }
                    let totalOutput = sessions.reduce(0) { $0 + $1.stats.sessionCompletionTokens }
                    Text("\(totalInput.formattedTokenCount) in / \(totalOutput.formattedTokenCount) out")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !tokenData.isEmpty {
                Chart(tokenData) { point in
                    BarMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Tokens", point.value)
                    )
                    .foregroundStyle(by: .value("Type", point.label))
                }
                .chartForegroundStyleScale([
                    "Input": Color.vibeAccent.opacity(0.7),
                    "Output": Color.vibePrimary.opacity(0.7),
                ])
                .chartLegend(position: .top, spacing: 8)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let tokens = value.as(Int.self) {
                                Text(tokens.formattedTokenCount)
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
