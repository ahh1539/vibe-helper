import SwiftUI
import Charts

private enum TokenFilter: String, CaseIterable {
    case both = "Both"
    case input = "Input"
    case output = "Output"
}

struct TokenDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let value: Int
}

struct TokenCard: View {
    let sessions: [Session]
    @State private var tokenFilter: TokenFilter = .both

    private var totalTokens: Int {
        sessions.reduce(0) { $0 + $1.stats.sessionTotalLlmTokens }
    }

    private var avgTokensPerSecond: Double {
        let speeds = sessions.map(\.stats.tokensPerSecond)
        guard !speeds.isEmpty else { return 0 }
        return speeds.reduce(0, +) / Double(speeds.count)
    }

    private var allTokenData: [TokenDataPoint] {
        sessions.sorted { $0.startTime < $1.startTime }.flatMap { session -> [TokenDataPoint] in
            [
                TokenDataPoint(date: session.startTime, label: "Input", value: session.stats.sessionPromptTokens),
                TokenDataPoint(date: session.startTime, label: "Output", value: session.stats.sessionCompletionTokens),
            ]
        }
    }

    private var filteredTokenData: [TokenDataPoint] {
        switch tokenFilter {
        case .both: return allTokenData
        case .input: return allTokenData.filter { $0.label == "Input" }
        case .output: return allTokenData.filter { $0.label == "Output" }
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

            HStack(spacing: 6) {
                ForEach(TokenFilter.allCases, id: \.rawValue) { filter in
                    Button(filter.rawValue) { tokenFilter = filter }
                        .buttonStyle(.plain)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(tokenFilter == filter ? Color.vibeAccent.opacity(0.15) : Color.clear)
                        .foregroundStyle(tokenFilter == filter ? Color.vibeAccent : .secondary)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(tokenFilter == filter ? Color.vibeAccent.opacity(0.4) : Color.secondary.opacity(0.2), lineWidth: 1))
                }
            }

            if !filteredTokenData.isEmpty {
                Chart(filteredTokenData) { point in
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
                .chartLegend(tokenFilter == .both ? .visible : .hidden)
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
                .frame(maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .cardStyle()
    }
}
