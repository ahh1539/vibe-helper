import SwiftUI
import Charts

struct ToolCallData: Identifiable {
    let id = UUID()
    let category: String
    let count: Int
    let color: Color
}

struct ToolUsageCard: View {
    let sessions: [Session]

    private var breakdown: (agreed: Int, rejected: Int, failed: Int, succeeded: Int) {
        let agreed = sessions.reduce(0) { $0 + $1.stats.toolCallsAgreed }
        let rejected = sessions.reduce(0) { $0 + $1.stats.toolCallsRejected }
        let failed = sessions.reduce(0) { $0 + $1.stats.toolCallsFailed }
        let succeeded = sessions.reduce(0) { $0 + $1.stats.toolCallsSucceeded }
        return (agreed, rejected, failed, succeeded)
    }

    private var chartData: [ToolCallData] {
        let b = breakdown
        return [
            ToolCallData(category: "Succeeded", count: b.succeeded, color: .vibeSuccess),
            ToolCallData(category: "Rejected", count: b.rejected, color: .vibeWarning),
            ToolCallData(category: "Failed", count: b.failed, color: .vibeDanger),
        ].filter { $0.count > 0 }
    }

    private var total: Int {
        let b = breakdown
        return b.agreed + b.rejected + b.failed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tool Calls")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(total)")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.vibeSuccess)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    let b = breakdown
                    if b.rejected > 0 {
                        Text("\(b.rejected) rejected")
                            .font(.caption)
                            .foregroundStyle(Color.vibeWarning)
                    }
                    if b.failed > 0 {
                        Text("\(b.failed) failed")
                            .font(.caption)
                            .foregroundStyle(Color.vibeDanger)
                    }
                }
            }

            if !chartData.isEmpty {
                Chart(chartData) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(3)
                }
                .frame(height: 120)

                HStack(spacing: 16) {
                    ForEach(chartData) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text("\(item.category) (\(item.count))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }
}
