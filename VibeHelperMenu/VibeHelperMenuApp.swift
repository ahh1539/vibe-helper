import SwiftUI

@main
struct VibeHelperMenuApp: App {
    @StateObject private var store = MenuBarStore()
    
    // This will cause the MenuBarExtra to rebuild when badgeValue changes
    @State private var badgeText: String = ""
    
    var body: some Scene {
        let title = badgeText.isEmpty ? "Vibe Helper" : "Vibe Helper (\(badgeText))"
        
        MenuBarExtra(title, systemImage: "v.circle") {
            MenuBarView(store: store)
        }
        .menuBarExtraStyle(.menu)
        .onChange(of: store.badgeValue) { newValue in
            badgeText = newValue ?? ""
        }
        .onAppear {
            badgeText = store.badgeValue ?? ""
        }
    }
}
