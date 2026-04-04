import SwiftUI

@main
struct VibeHelperApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar") }
                SkillsListView()
                    .tabItem { Label("Skills", systemImage: "sparkles") }
                ModelsSettingsView()
                    .tabItem { Label("Models", systemImage: "cpu") }
            }
            .preferredColorScheme(selectedMode.colorScheme)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 700)
    }
}
