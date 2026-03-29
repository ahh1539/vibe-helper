import SwiftUI

@main
struct VibeHelperApp: App {
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .preferredColorScheme(selectedMode.colorScheme)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 700)
        .commands {
            CommandGroup(after: .appSettings) {
                Menu("Appearance") {
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
                }
            }
        }
    }
}
