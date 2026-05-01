import SwiftUI
import AppKit

private enum Metrics {
    // Dimensions
    static let popoverWidth: CGFloat = 280
    static let statColumnHeight: CGFloat = 32

    // Paddings
    static let horizontalPadding: CGFloat = 14
    static let verticalPadding: CGFloat = 10
    static let bottomPadding: CGFloat = 10
    static let topPadding: CGFloat = 12
    static let headerBottomPadding: CGFloat = 2
    static let statsVerticalPadding: CGFloat = 12
    static let footerTopPadding: CGFloat = 10
    static let smallPadding: CGFloat = 6
    static let tinyPadding: CGFloat = 4
    static let zeroPadding: CGFloat = 0

    // Corner radii
    static let cornerRadius: CGFloat = 12
    static let buttonCornerRadius: CGFloat = 8
    static let timeRangeButtonCornerRadius: CGFloat = 6

    // Font sizes
    static let headerFontSize: CGFloat = 13
    static let timeRangeFontSize: CGFloat = 12
    static let statValueFontSize: CGFloat = 15
    static let statLabelFontSize: CGFloat = 10
    static let smallFontSize: CGFloat = 11
    static let tinyFontSize: CGFloat = 9
    static let checkmarkFontSize: CGFloat = 10

    // Icon sizes
    static let logoIconSize: CGFloat = 15
    static let refreshIconSize: CGFloat = 11
    static let tpsIconSize: CGFloat = 8
    static let indicatorSize: CGFloat = 6
    static let progressSize: CGFloat = 16
    static let refreshMenuIconSize: CGFloat = 9

    // Animation durations
    static let timeRangeAnimationDuration: CGFloat = 0.15
    static let indicatorAnimationDuration: CGFloat = 1.2
}

struct MenuBarPopoverView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var processMonitor: VibeProcessMonitor

    private let timeRanges: [(label: String, range: TimeRange)] = [
        ("Today", .today),
        ("Week", .week),
        ("Month", .month)
    ]

    private let refreshOptions: [(label: String, minutes: Int)] = [
        ("Manual", 0),
        ("1 min", 1),
        ("2 min", 2),
        ("5 min", 5),
        ("10 min", 10)
    ]

    var body: some View {
        VStack(spacing: Metrics.zeroPadding) {
            header
                .padding(.bottom, Metrics.headerBottomPadding)

            timeRangePicker
                .padding(.vertical, Metrics.verticalPadding)

            statsSection
                .padding(.vertical, Metrics.statsVerticalPadding)

            footer
        }
        .frame(width: Metrics.popoverWidth)
        .padding(.top, Metrics.topPadding)
        .padding(.bottom, Metrics.bottomPadding)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.cornerRadius))
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Metrics.smallPadding) {
            Image(systemName: "v.circle.fill")
                .font(.system(size: Metrics.logoIconSize, weight: .medium))
                .foregroundStyle(Color.accentColor)

            Text("Vibe Helper")
                .font(.system(size: Metrics.headerFontSize, weight: .semibold))

            Spacer()

            if let last = sessionStore.lastRefreshedAt {
                Text(relativeTimeString(from: last))
                    .font(.system(size: Metrics.tinyFontSize).monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if sessionStore.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: Metrics.progressSize, height: Metrics.progressSize)
            } else {
                Button {
                    Task { await sessionStore.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: Metrics.smallFontSize))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: Metrics.zeroPadding) {
            ForEach(timeRanges, id: \.label) { item in
                Button {
                    withAnimation(.easeInOut(duration: Metrics.timeRangeAnimationDuration)) {
                        sessionStore.menuBarTimeRange = item.range
                    }
                } label: {
                    Text(item.label)
                        .font(.system(size: Metrics.timeRangeFontSize, weight: isSelected(item.range) ? .semibold : .medium))
                        .foregroundStyle(isSelected(item.range) ? .white : .primary)
                        .frame(maxWidth: .infinity, minHeight: Metrics.statColumnHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(isSelected(item.range) ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Metrics.timeRangeButtonCornerRadius))
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(Metrics.headerBottomPadding)
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: Metrics.buttonCornerRadius))
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private func isSelected(_ range: TimeRange) -> Bool {
        switch (sessionStore.menuBarTimeRange, range) {
        case (.today, .today), (.week, .week), (.month, .month):
            return true
        default:
            return false
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        let stats = currentStats

        return VStack(spacing: Metrics.tinyPadding) {
            HStack(spacing: Metrics.zeroPadding) {
                statColumn(
                    label: "Cost",
                    value: stats.cost.formatted(.currency(code: "USD").precision(.fractionLength(2)))
                )
                Divider()
                    .frame(height: Metrics.statColumnHeight)
                statColumn(
                    label: "Sessions",
                    value: "\(stats.sessions)"
                )
                Divider()
                    .frame(height: Metrics.statColumnHeight)
                statColumn(
                    label: "Tokens",
                    value: stats.tokens.formattedTokenCount
                )
            }

            HStack(spacing: Metrics.tinyPadding) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: Metrics.tpsIconSize))
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f t/s", stats.tokensPerSecond))
                    .font(.system(size: Metrics.smallFontSize, weight: .medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
    }

    private var currentStats: (cost: Double, sessions: Int, tokens: Int, tokensPerSecond: Double) {
        switch sessionStore.menuBarTimeRange {
        case .today:
            return (
                sessionStore.costToday,
                sessionStore.sessionsToday,
                sessionStore.tokensToday,
                sessionStore.tokensPerSecondToday
            )
        case .week:
            return (
                sessionStore.costThisWeek,
                sessionStore.sessionsThisWeek,
                sessionStore.tokensThisWeek,
                sessionStore.tokensPerSecondThisWeek
            )
        case .month:
            return (
                sessionStore.costThisMonth,
                sessionStore.sessionsThisMonth,
                sessionStore.tokensThisMonth,
                sessionStore.tokensPerSecondThisMonth
            )
        default:
            return (
                sessionStore.costToday,
                sessionStore.sessionsToday,
                sessionStore.tokensToday,
                sessionStore.tokensPerSecondToday
            )
        }
    }

    private func statColumn(label: String, value: String) -> some View {
        VStack(spacing: Metrics.tinyPadding) {
            Text(value)
                .font(.system(size: Metrics.statValueFontSize, weight: .semibold).monospacedDigit())
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: Metrics.statLabelFontSize, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: Metrics.smallPadding) {
            // Status row
            HStack(spacing: Metrics.zeroPadding) {
                activeIndicator
                Spacer()
                refreshMenu
            }

            // Actions row
            HStack(spacing: Metrics.zeroPadding) {
                Button("Dashboard") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "dashboard")
                }
                .buttonStyle(.plain)
                .font(.system(size: Metrics.smallFontSize, weight: .medium))
                .foregroundStyle(Color.accentColor)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: Metrics.smallFontSize))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, Metrics.horizontalPadding)
        .padding(.top, Metrics.footerTopPadding)
    }

    private var activeIndicator: some View {
        HStack(spacing: Metrics.smallPadding) {
            ZStack {
                Circle()
                    .fill(processMonitor.isRunning ? Color.vibeSuccess : Color.secondary.opacity(0.4))
                    .frame(width: Metrics.indicatorSize, height: Metrics.indicatorSize)

                if processMonitor.isRunning {
                    Circle()
                        .stroke(Color.vibeSuccess.opacity(0.4), lineWidth: 2)
                        .frame(width: Metrics.indicatorSize, height: Metrics.indicatorSize)
                        .scaleEffect(1.6)
                        .opacity(0)
                        .animation(
                            .easeInOut(duration: Metrics.indicatorAnimationDuration).repeatForever(autoreverses: false),
                            value: true
                        )
                }
            }

            Text(processMonitor.isRunning ? "Active" : "Idle")
                .font(.system(size: Metrics.smallFontSize, weight: .medium))
                .foregroundStyle(processMonitor.isRunning ? .primary : .secondary)
        }
    }

    private var refreshMenu: some View {
        Menu {
            ForEach(refreshOptions, id: \.minutes) { option in
                Button {
                    sessionStore.menuBarRefreshInterval = option.minutes
                } label: {
                    HStack {
                        Text(option.label)
                        if sessionStore.menuBarRefreshInterval == option.minutes {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: Metrics.checkmarkFontSize, weight: .bold))
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Metrics.tinyPadding) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: Metrics.refreshMenuIconSize))
                Text(refreshLabel)
                    .font(.system(size: Metrics.tinyFontSize, weight: .medium))
            }
            .foregroundStyle(.secondary)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private var refreshLabel: String {
        let interval = sessionStore.menuBarRefreshInterval
        if interval == 0 { return "Manual" }
        return "\(interval)m"
    }

    // MARK: - Helpers

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private func relativeTimeString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 10 {
            return "Just now"
        } else if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h ago"
        } else {
            return Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
        }
    }
}
