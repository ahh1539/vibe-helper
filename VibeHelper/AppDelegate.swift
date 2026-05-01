import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let stores = StoresContainer.shared

        Task {
            await stores.sessionStore.load()
            stores.sessionStore.startWatching()
            await stores.skillStore.load()
            stores.skillStore.startWatching()
            await stores.configStore.load()
            stores.configStore.startWatching()
        }

        stores.sessionStore.startRefreshTimerIfNeeded()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            sender.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }
}
