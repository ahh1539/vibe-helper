import SwiftUI

struct DashboardView: View {
    @StateObject private var store = SessionStore()
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Toolbar
                HStack {
                    Text("Vibe Helper")
                        .font(.title2.weight(.bold))

                    Spacer()

                    ProjectFilterView(
                        projects: store.projects,
                        selectedProject: $store.selectedProject
                    )

                    TimeRangePickerView(timeRange: $store.timeRange)

                    Menu {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Button {
                                appearanceMode = mode.rawValue
                            } label: {
                                HStack {
                                    Text(mode.rawValue)
                                    if appearanceMode == mode.rawValue {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: appearanceMode == "Dark" ? "moon.fill" :
                              appearanceMode == "Light" ? "sun.max.fill" : "circle.lefthalf.filled")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Appearance")

                    Button {
                        Task { await store.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh")
                }
                .padding(.horizontal, 4)

                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Top row: Cost + Tokens
                    HStack(spacing: 16) {
                        CostCard(sessions: store.filteredSessions)
                        TokenCard(sessions: store.filteredSessions)
                    }
                    .frame(height: 280)

                    // Second row: Activity + Tool Usage
                    HStack(spacing: 16) {
                        ActivityCard(sessions: store.filteredSessions)
                        ToolUsageCard(sessions: store.filteredSessions)
                    }
                    .frame(height: 280)

                    // Session list
                    SessionListView(
                        sessions: store.filteredSessions,
                        selectedSession: $store.selectedSession
                    )
                }
            }
            .padding(20)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await store.load()
            store.startWatching()
        }
        .sheet(item: $store.selectedSession) { session in
            SessionDetailView(session: session)
        }
    }
}
