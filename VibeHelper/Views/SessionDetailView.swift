import SwiftUI

struct SessionDetailView: View {
    let session: Session
    var onReplay: () -> Void
    var onPopToRoot: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Breadcrumb
                SessionBreadcrumbBar(items: [
                    BreadcrumbItem(label: "Dashboard", action: onPopToRoot),
                    BreadcrumbItem(label: session.title ?? "Untitled Session", action: {})
                ])

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
                    Button {
                        onReplay()
                    } label: {
                        Label("Replay", systemImage: "play.circle")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.vibePrimary)
                    .disabled(session.directoryURL == nil)
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
                        LabeledValue(label: "Prompt Tokens", value: session.stats.sessionPromptTokens.formattedTokenCount, valueFont: .title3.weight(.medium))
                        LabeledValue(label: "Completion Tokens", value: session.stats.sessionCompletionTokens.formattedTokenCount, valueFont: .title3.weight(.medium))
                        LabeledValue(label: "Total LLM Tokens", value: session.stats.sessionTotalLlmTokens.formattedTokenCount, valueFont: .title3.weight(.medium))
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
                        LabeledValue(label: "Input Price", value: String(format: "$%.2f / 1M tokens", session.stats.inputPricePerMillion))
                        LabeledValue(label: "Output Price", value: String(format: "$%.2f / 1M tokens", session.stats.outputPricePerMillion))
                    }
                }

                Divider()

                // Timestamps
                VStack(alignment: .leading, spacing: 8) {
                    Text("Timing")
                        .font(.headline)
                    HStack(spacing: 20) {
                        LabeledValue(label: "Started", value: session.startTime.shortFormatted)
                        LabeledValue(label: "Ended", value: session.endTime.shortFormatted)
                        LabeledValue(label: "Last Turn", value: String(format: "%.1fs", session.stats.lastTurnDuration))
                    }
                }

                Divider()

                // Model
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.headline)
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Active Model")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(session.activeModelName)
                                .font(.body.weight(.medium))
                                .foregroundStyle(Color.vibeAccent)
                        }
                        if let modelDetails = session.config?.models?.first(where: {
                            $0.alias == session.config?.activeModel
                        }) {
                            LabeledValue(label: "Provider", value: modelDetails.provider)
                        }
                        if let profile = session.agentProfileName {
                            LabeledValue(label: "Agent Profile", value: profile)
                        }
                    }
                }

                if let commit = session.gitCommit {
                    Divider()
                    LabeledValue(label: "Git Commit", value: String(commit.prefix(12)), valueFont: .system(.body, design: .monospaced))
                }
            }
            .padding(24)
        }
        .frame(minWidth: 550, minHeight: 500)
    }
}

struct LabeledValue: View {
    let label: String
    let value: String
    var valueFont: Font = .body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(valueFont)
        }
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
