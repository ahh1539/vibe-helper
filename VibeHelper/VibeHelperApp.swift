import SwiftUI

@main
struct VibeHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some Scene {
        Window("Dashboard", id: "dashboard") {
            TabView {
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar") }
                SkillsListView()
                    .tabItem { Label("Skills", systemImage: "sparkles") }
                ModelsSettingsView()
                    .tabItem { Label("Models", systemImage: "cpu") }
            }
            .preferredColorScheme(selectedMode.colorScheme)
            .environmentObject(StoresContainer.shared.sessionStore)
            .environmentObject(StoresContainer.shared.configStore)
            .environmentObject(StoresContainer.shared.skillStore)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 700)

        MenuBarExtra("Vibe Helper", systemImage: "v.circle.fill") {
            MenuBarPopoverView()
                .environmentObject(StoresContainer.shared.sessionStore)
                .environmentObject(StoresContainer.shared.processMonitor)
        }
        .menuBarExtraStyle(.window)
    }
}
