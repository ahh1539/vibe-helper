import Foundation
import SwiftUI

@MainActor
final class ConfigStore: ObservableObject {
    @Published var models: [VibeModel] = []
    @Published var providers: [VibeProvider] = []
    @Published var isLoading = false
    @Published var lastError: String? = nil
    @Published var backups: [ConfigBackup] = []

    private var fileWatcher: FileWatcher?
    private var rawContent: String = ""

    static let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/config.toml")

    private static let backupDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()

    // MARK: - Load

    func load() async {
        isLoading = true
        lastError = nil
        guard let content = try? String(contentsOf: Self.configFile, encoding: .utf8) else {
            lastError = "Could not read config.toml"
            isLoading = false
            return
        }
        rawContent = content
        models = TomlParser.parseModels(from: content)
        providers = TomlParser.parseProviders(from: content)
        backups = Self.loadBackups()
        isLoading = false
    }

    // MARK: - Safe Write Operations

    func updateModel(_ model: VibeModel) throws {
        let backup = try createBackup()
        var content = rawContent

        guard let range = TomlParser.findBlockRange(in: content, header: "[[models]]", matchingName: model.name) else {
            throw ConfigError.blockNotFound("[[models]] with name \"\(model.name)\"")
        }

        let newBlock = TomlParser.serializeModel(model) + "\n\n"
        content.replaceSubrange(range, with: newBlock)
        try safeWrite(content, backup: backup)
    }

    func updateProvider(_ provider: VibeProvider) throws {
        let backup = try createBackup()
        var content = rawContent

        guard let range = TomlParser.findBlockRange(in: content, header: "[[providers]]", matchingName: provider.name) else {
            throw ConfigError.blockNotFound("[[providers]] with name \"\(provider.name)\"")
        }

        let newBlock = TomlParser.serializeProvider(provider) + "\n\n"
        content.replaceSubrange(range, with: newBlock)
        try safeWrite(content, backup: backup)
    }

    // MARK: - Restore

    func restoreBackup(_ backup: ConfigBackup) throws {
        // Before restoring, create a backup of the current state
        _ = try createBackup()

        // Validate the backup file parses correctly before restoring
        guard let backupContent = try? String(contentsOf: backup.url, encoding: .utf8) else {
            throw ConfigError.validationFailed("Could not read backup file")
        }
        let parsedModels = TomlParser.parseModels(from: backupContent)
        let parsedProviders = TomlParser.parseProviders(from: backupContent)
        guard !parsedModels.isEmpty || !parsedProviders.isEmpty else {
            throw ConfigError.validationFailed("Backup file appears invalid — no models or providers found")
        }

        try backupContent.write(to: Self.configFile, atomically: true, encoding: .utf8)
        rawContent = backupContent
        models = parsedModels
        providers = parsedProviders
        backups = Self.loadBackups()
    }

    private static func loadBackups() -> [ConfigBackup] {
        let fm = FileManager.default
        let dir = configFile.deletingLastPathComponent()
        guard let contents = try? fm.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        return contents
            .filter { $0.lastPathComponent.hasPrefix("config.toml.bak.") }
            .compactMap { url -> ConfigBackup? in
                let attrs = try? fm.attributesOfItem(atPath: url.path)
                let date = attrs?[.modificationDate] as? Date ?? Date.distantPast
                return ConfigBackup(url: url, date: date)
            }
            .sorted { $0.date > $1.date }
    }

    // MARK: - Safety Infrastructure

    private func createBackup() throws -> URL {
        let fm = FileManager.default
        let timestamp = Self.backupDateFormatter.string(from: Date())
        let backupURL = Self.configFile.deletingLastPathComponent()
            .appendingPathComponent("config.toml.bak.\(timestamp)")
        try fm.copyItem(at: Self.configFile, to: backupURL)
        return backupURL
    }

    private func safeWrite(_ content: String, backup: URL) throws {
        // Write atomically
        try content.write(to: Self.configFile, atomically: true, encoding: .utf8)

        // Validate: re-read and re-parse to confirm file integrity
        guard let written = try? String(contentsOf: Self.configFile, encoding: .utf8) else {
            // Restore from backup
            try? FileManager.default.removeItem(at: Self.configFile)
            try? FileManager.default.copyItem(at: backup, to: Self.configFile)
            throw ConfigError.validationFailed("Could not re-read config.toml after write")
        }

        let parsedModels = TomlParser.parseModels(from: written)
        let parsedProviders = TomlParser.parseProviders(from: written)
        if parsedModels.isEmpty && !models.isEmpty {
            // Restore from backup — we lost all models
            try? FileManager.default.removeItem(at: Self.configFile)
            try? FileManager.default.copyItem(at: backup, to: Self.configFile)
            throw ConfigError.validationFailed("Models section was corrupted during write — restored from backup")
        }

        if parsedProviders.isEmpty && !providers.isEmpty {
            try? FileManager.default.removeItem(at: Self.configFile)
            try? FileManager.default.copyItem(at: backup, to: Self.configFile)
            throw ConfigError.validationFailed("Providers section was corrupted during write — restored from backup")
        }

        // Update local state
        rawContent = written
        self.models = parsedModels
        self.providers = parsedProviders
        self.backups = Self.loadBackups()
    }

    // MARK: - File Watching

    func startWatching() {
        let dir = Self.configFile.deletingLastPathComponent().path
        fileWatcher = FileWatcher(path: dir) { [weak self] in
            Task { @MainActor in
                await self?.load()
            }
        }
        fileWatcher?.start()
    }

    func stopWatching() {
        fileWatcher?.stop()
    }

    /// Clean up resources. Can be called manually if needed.
    @MainActor
    func cleanup() {
        stopWatching()
    }
}

struct ConfigBackup: Identifiable {
    let url: URL
    let date: Date
    var id: String { url.lastPathComponent }

    var displayName: String {
        url.lastPathComponent
            .replacingOccurrences(of: "config.toml.bak.", with: "")
    }
}

enum ConfigError: LocalizedError {
    case blockNotFound(String)
    case validationFailed(String)

    var errorDescription: String? {
        switch self {
        case .blockNotFound(let block): return "Could not find \(block) in config.toml"
        case .validationFailed(let msg): return msg
        }
    }
}
