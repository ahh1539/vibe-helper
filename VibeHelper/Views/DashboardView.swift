import SwiftUI

enum Route: Hashable {
    case session(Session)
    case replay(Session)
}

struct DashboardView: View {
    @EnvironmentObject var sessionStore: SessionStore
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 16) {
                    // Toolbar
                    HStack {
                        Text("Vibe Helper")
                            .font(.title2.weight(.bold))

                        Spacer()

                        ProjectFilterView(
                            projects: sessionStore.projects,
                            selectedProject: $sessionStore.selectedProject
                        )

                        TimeRangePickerView(timeRange: $sessionStore.timeRange)

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
                            Task { await sessionStore.load() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.plain)
                        .help("Refresh")
                    }
                    .padding(.horizontal, 4)

                    if sessionStore.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Top row: Cost + Tokens
                        HStack(spacing: 16) {
                            CostCard(sessions: sessionStore.filteredSessions)
                            TokenCard(sessions: sessionStore.filteredSessions)
                        }
                        .frame(height: 280)

                        // Second row: Activity + Tool Usage
                        HStack(spacing: 16) {
                            ActivityCard(sessions: sessionStore.filteredSessions)
                            ToolUsageCard(sessions: sessionStore.filteredSessions)
                        }
                        .frame(height: 280)

                        // Session list
                        SessionListView(
                            sessions: sessionStore.filteredSessions,
                            onSelect: { session in
                                navigationPath.append(Route.session(session))
                            }
                        )
                    }
                }
                .padding(20)
            }
            .frame(minWidth: 800, minHeight: 600)
            .background(Color(nsColor: .windowBackgroundColor))
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .session(let session):
                    SessionDetailView(
                        session: session,
                        onReplay: { navigationPath.append(Route.replay(session)) },
                        onPopToRoot: { navigationPath.removeLast(navigationPath.count) }
                    )
                case .replay(let session):
                    SessionReplayView(
                        session: session,
                        onPopToRoot: { navigationPath.removeLast(navigationPath.count) },
                        onPop: { navigationPath.removeLast() }
                    )
                }
            }
        }
    }
}
