import Foundation

/// Shared container for all app stores to ensure single instances
/// Uses lazy initialization to prevent retain cycles.
/// Not an ObservableObject - views observe individual stores directly.
@MainActor
final class StoresContainer {
    static let shared = StoresContainer()

    // Lazy initialization prevents retain cycles:
    // Container doesn't strongly retain stores until they're accessed.
    // Stores are ObservableObject and are injected into views via environmentObject.
    private lazy var _sessionStore = SessionStore()
    private lazy var _skillStore = SkillStore()
    private lazy var _configStore = ConfigStore()
    private lazy var _processMonitor = VibeProcessMonitor()

    var sessionStore: SessionStore { _sessionStore }
    var skillStore: SkillStore { _skillStore }
    var configStore: ConfigStore { _configStore }
    var processMonitor: VibeProcessMonitor { _processMonitor }

    private init() {}
}
