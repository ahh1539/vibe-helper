import SwiftUI

struct SessionDetailView: View {
    let session: Session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.title ?? "Untitled Session")
                            .font(.title2.weight(.semibold))
                        HStack(spacing: 12) {
                            Label(session.projectName, systemImage: "folder")
                            if let branch = session.gitBranch {
                                Label(branch, systemImage: "arrow.triangle.branch")
                            }
                            Label(session.formattedDuration, systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    StatBox(title: "Cost", value: session.stats.formattedCost, color: .vibePrimary)
                    StatBox(title: "Total Tokens", value: session.stats.formattedTokens, color: .vibeAccent)
                    StatBox(title: "Steps", value: "\(session.stats.steps)", color: .vibeSuccess)
                    StatBox(title: "Messages", value: "\(session.totalMessages)", color: .vibePrimary)
                    StatBox(title: "Tokens/sec", value: String(format: "%.0f", session.stats.tokensPerSecond), color: .vibeAccent)
                    StatBox(title: "Context", value: session.stats.contextTokens.formattedTokenCount, color: .vibeSuccess)
                }

                Divider()

                // Token Breakdown
                VStack(alignment: .leading, spacing: 8) {
                    Text("Token Breakdown")
                        .font(.headline)

                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prompt Tokens")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.stats.sessionPromptTokens.formattedTokenCount)
                                .font(.title3.weight(.medium))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Completion Tokens")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.stats.sessionCompletionTokens.formattedTokenCount)
                                .font(.title3.weight(.medium))
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total LLM Tokens")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.stats.sessionTotalLlmTokens.formattedTokenCount)
                                .font(.title3.weight(.medium))
                        }
                    }
                }

                Divider()

                // Tool Calls
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tool Calls")
                        .font(.headline)

                    HStack(spacing: 20) {
                        ToolStat(label: "Succeeded", count: session.stats.toolCallsSucceeded, color: .vibeSuccess)
                        ToolStat(label: "Agreed", count: session.stats.toolCallsAgreed, color: .vibePrimary)
                        ToolStat(label: "Rejected", count: session.stats.toolCallsRejected, color: .vibeWarning)
                        ToolStat(label: "Failed", count: session.stats.toolCallsFailed, color: .vibeDanger)
                    }
                }

                Divider()

                // Pricing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Pricing")
                        .font(.headline)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Input Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.2f / 1M tokens", session.stats.inputPricePerMillion))
                                .font(.body)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Output Price")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "$%.2f / 1M tokens", session.stats.outputPricePerMillion))
                                .font(.body)
                        }
                    }
                }

                Divider()

                // Timestamps
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timing")
                        .font(.headline)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Started")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.startTime.shortFormatted)
                                .font(.body)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ended")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.endTime.shortFormatted)
                                .font(.body)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Last Turn")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(String(format: "%.1fs", session.stats.lastTurnDuration))
                                .font(.body)
                        }
                    }
                }

                if let commit = session.gitCommit {
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Git Commit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(commit.prefix(12)))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            .padding(24)
        }
        .frame(minWidth: 550, minHeight: 500)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ToolStat: View {
    let label: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.title3.weight(.medium))
                .foregroundStyle(color)
        }
    }
}
