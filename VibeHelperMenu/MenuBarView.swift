import SwiftUI
import AppKit

/// Simple menu view for menu bar app
/// Shows stats in a traditional menu format with text items
struct MenuBarView: View {
    @StateObject var store: MenuBarStore
    
    // Formatters
    private var costFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    private var tokenFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter
    }
    
    private func formattedCost(_ value: Double) -> String {
        costFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private func formattedTokens(_ value: Int) -> String {
        tokenFormatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    var body: some View {
        Group {
            if store.isLoading && store.sessions.isEmpty {
                // Initial loading state
                Button("Loading...") { }
                    .disabled(true)
            } else {
                // Main menu content
                menuContent
            }
        }
        .task {
            // Load sessions on first menu open (lazy loading)
            if store.sessions.isEmpty {
                await store.load()
            }
        }
    }
    
    private var menuContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Today section
            MenuSection(title: "Today") {
                statRow(label: "Cost", value: formattedCost(store.todayCost))
                statRow(label: "Sessions", value: "\(store.todaySessions)")
                statRow(label: "Tokens", value: formattedTokens(store.todayTokens))
            }
            
            Divider()
            
            // This Week section
            MenuSection(title: "This Week") {
                statRow(label: "Cost", value: formattedCost(store.weekCost))
                statRow(label: "Sessions", value: "\(store.weekSessions)")
                statRow(label: "Tokens", value: formattedTokens(store.weekTokens))
            }
            
            Divider()
            
            // All Time section
            MenuSection(title: "All Time") {
                statRow(label: "Cost", value: formattedCost(store.totalCost))
                statRow(label: "Sessions", value: "\(store.totalSessions)")
                statRow(label: "Tokens", value: formattedTokens(store.totalTokens))
            }
            
            Divider()
            
            // Active session indicator
            HStack {
                Text("Active")
                Spacer()
                Text(store.isVibeRunning ? "Yes" : "No")
                    .foregroundColor(store.isVibeRunning ? .green : .secondary)
            }
            .font(.system(size: 12, weight: .regular))
            .monospacedDigit()
            
            Divider()
            
            // Badge settings
            Menu {
                ForEach(MenuBarStore.BadgeType.allCases, id: \.self) { type in
                    Button {
                        store.badgeType = type
                    } label: {
                        HStack {
                            Text("Badge: \(type.rawValue)")
                            if store.badgeType == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Text("Badge: \(store.badgeType.rawValue)")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 12))
            
            Divider()
            
            // Actions
            Button {
                Task { await store.refresh() }
            } label: {
                HStack {
                    Text("Refresh")
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                }
            }
            .font(.system(size: 12))
            .keyboardShortcut("r")
            
            // Open Dashboard
            Button {
                openDashboard()
            } label: {
                HStack {
                    Text("Open Dashboard")
                    Spacer()
                    Image(systemName: "safari")
                }
            }
            .font(.system(size: 12))
            
            Divider()
            
            // Quit
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("Quit")
            }
            .font(.system(size: 12))
            .keyboardShortcut("q")
        }
        .padding(8)
        .frame(width: 240)
    }
    
    private func statRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 70, alignment: .leading)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
        .font(.system(size: 12, weight: .regular))
        .monospacedDigit()
    }
    
    private func openDashboard() {
        // Try to open the main VibeHelper app
        let appName = "Vibe Helper"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.ahh1539.VibeHelper") {
            NSWorkspace.shared.open(appURL)
        } else {
            // Fallback: try to find it in Applications
            let applicationsURL = FileManager.default.urls(for: .applicationsDirectory, in: .userDomainMask).first
            let appURL = applicationsURL?.appendingPathComponent("Vibe Helper.app")
            if let appURL = appURL, FileManager.default.fileExists(atPath: appURL.path) {
                NSWorkspace.shared.open(appURL)
            } else {
                // Show alert that dashboard app not found
                let alert = NSAlert()
                alert.messageText = "Dashboard Not Found"
                alert.informativeText = "The Vibe Helper dashboard app could not be found. Please install it from the releases page."
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
        }
    }
}

/// Helper view for menu sections
private struct MenuSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            content
        }
    }
}
