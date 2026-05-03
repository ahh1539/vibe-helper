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
    var rawContent: String = ""

    static let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/config.toml")

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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
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

    // MARK: - MCP Server Operations

    /// Writes MCP server configuration safely to config.toml with atomic backup
    /// - Parameters:
    ///   - content: The full config.toml content with MCP servers updated
    ///   - servers: The MCP servers array to write back
    func writeMcpServersContent(_ content: String, servers: [McpServer]) async throws {
        // Create backup before any write
        let backup = try createBackup()
        
        // Validate the new content parses correctly
        let parsedServers = TomlMcpParser.parseMcpServers(from: content)
        guard parsedServers.count == servers.count else {
            throw ConfigError.validationFailed("Server count mismatch after write")
        }
        
        // Atomic write
        try content.write(to: Self.configFile, atomically: true, encoding: .utf8)
        
        // Update local state
        self.rawContent = content
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
}

// MARK: - MCP Server TOML Parser

/// Parses and serializes MCP server configurations from TOML
enum TomlMcpParser {
    static let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/config.toml")

    /// Parse all `[[mcp_servers]]` blocks from raw TOML content.
    static func parseMcpServers(from content: String = "") -> [McpServer] {
        let effectiveContent: String
        if content.isEmpty {
            effectiveContent = (try? String(contentsOf: configFile, encoding: .utf8)) ?? ""
        } else {
            effectiveContent = content
        }
        guard !effectiveContent.isEmpty else { return [] }
        
        let blocks = extractBlocks(from: effectiveContent, header: "[[mcp_servers]]")
        return blocks.compactMap { block in
            parseServerFromBlock(block)
        }
    }

    /// Parse a single server from a TOML block
    private static func parseServerFromBlock(_ block: String) -> McpServer? {
        var server = McpServer()
        let kv = parseKeyValues(block)
        
        server.name = kv["name"] ?? "Unnamed Server"
        
        if let transport = kv["transport"] {
            server.transport = transport
        }
        
        if server.transport == "stdio" {
            server.command = kv["command"] ?? ""
            if let args = kv["args"] {
                server.args = args.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
            }
        } else {
            server.url = kv["url"] ?? ""
        }
        
        // Parse env dictionary
        if let env = kv["env"], !env.isEmpty {
            server.env = parseDictionary(env)
        }
        
        // Parse headers dictionary
        if let headers = kv["headers"], !headers.isEmpty {
            server.headers = parseDictionary(headers)
        }
        
        server.apiKeyEnv = kv["api_key_env"] ?? ""
        server.apiKeyHeader = kv["api_key_header"] ?? ""
        server.apiKeyFormat = kv["api_key_format"] ?? ""
        
        if let timeout = kv["timeout"], let value = Int(timeout) {
            server.timeout = value
        }
        
        if let startupTimeout = kv["startup_timeout_sec"], let value = Int(startupTimeout) {
            server.startupTimeoutSec = value
        }
        
        if let toolTimeout = kv["tool_timeout_sec"], let value = Int(toolTimeout) {
            server.toolTimeoutSec = value
        }
        
        if let isEnabled = kv["is_enabled"] {
            server.isEnabled = isEnabled.lowercased() == "true"
        }
        
        return server
    }

        /// Serialize a single MCP server to a TOML `[[mcp_servers]]` block.
    static func serializeMcpServer(_ server: McpServer) -> String {
        var lines: [String] = ["[[mcp_servers]]"]
        
        lines.append("name = \"\(escapeTomlString(server.name))\"")
        lines.append("transport = \"\(escapeTomlString(server.transport))\"")
        
        if server.transport == "stdio" {
            lines.append("command = \"\(escapeTomlString(server.command))\"")
            if !server.args.isEmpty {
                let escapedArgs = server.args.map { TomlMcpParser.escapeTomlString($0) }
                let argsString = escapedArgs.map { "\"" + $0 + "\"" }.joined(separator: ", ")
                lines.append("args = [" + argsString + "]")
            }
        } else {
            lines.append("url = \"\(escapeTomlString(server.url))\"")
        }
        
        if !server.env.isEmpty {
            let envPairs = server.env.map { key, value -> String in
                let escapedKey = TomlMcpParser.escapeTomlString(key)
                let escapedValue = TomlMcpParser.escapeTomlString(value)
                return "\"" + escapedKey + "\" = \"" + escapedValue + "\""
            }
            let envString = envPairs.joined(separator: ", ")
            lines.append("env = { " + envString + " }")
        }
        
        if !server.headers.isEmpty {
            let headerPairs = server.headers.map { key, value -> String in
                let escapedKey = TomlMcpParser.escapeTomlString(key)
                let escapedValue = TomlMcpParser.escapeTomlString(value)
                return "\"" + escapedKey + "\" = \"" + escapedValue + "\""
            }
            let headersString = headerPairs.joined(separator: ", ")
            lines.append("headers = { " + headersString + " }")
        }
        
        lines.append("api_key_env = \"\(escapeTomlString(server.apiKeyEnv))\"")
        lines.append("api_key_header = \"\(escapeTomlString(server.apiKeyHeader))\"")
        lines.append("api_key_format = \"\(escapeTomlString(server.apiKeyFormat))\"")
        lines.append("timeout = \(server.timeout)")
        lines.append("startup_timeout_sec = \(server.startupTimeoutSec)")
        lines.append("tool_timeout_sec = \(server.toolTimeoutSec)")
        lines.append("is_enabled = \(server.isEnabled ? "true" : "false")")
        
        return lines.joined(separator: "\n")
    }

    // MARK: - TOML Escaping

    private static func escapeTomlString(_ str: String) -> String {
        str.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
           .replacingOccurrences(of: "\n", with: "\\n")
           .replacingOccurrences(of: "\r", with: "\\r")
           .replacingOccurrences(of: "\t", with: "\\t")
    }

    // MARK: - Helper Methods

    private static func extractBlocks(from content: String, header: String) -> [String] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [String] = []
        var currentBlock: [String]? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed == header {
                if let block = currentBlock {
                    blocks.append(block.joined(separator: "\n"))
                }
                currentBlock = []
            } else if trimmed.hasPrefix("[[") || (trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[[")) {
                if let block = currentBlock {
                    blocks.append(block.joined(separator: "\n"))
                    currentBlock = nil
                }
            } else if currentBlock != nil {
                currentBlock?.append(line)
            }
        }
        
        if let block = currentBlock {
            blocks.append(block.joined(separator: "\n"))
        }
        
        return blocks
    }

    private static func parseKeyValues(_ block: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in block.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), !trimmed.hasPrefix("[[") else { continue }
            guard let eqIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<eqIndex]).trimmingCharacters(in: .whitespaces)
            let value = extractValueFromToml(String(trimmed[trimmed.index(after: eqIndex)...]))
            result[key] = value
        }
        return result
    }
    
    private static func parseDictionary(_ dictString: String) -> [String: String] {
        var result: [String: String] = [:]
        // Simple parser for { "key": "value", "key2": "value2" } format
        let clean = dictString
            .trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
            .replacingOccurrences(of: "\"", with: "")
        
        let pairs = clean.components(separatedBy: ",")
        for pair in pairs {
            let parts = pair.components(separatedBy: ":")
            if parts.count == 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let value = parts[1].trimmingCharacters(in: .whitespaces)
                result[key] = value
            }
        }
        return result
    }
    
    private static func extractValueFromToml(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        
        // Strip table marker [[...]]
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            return String(trimmed.dropFirst().dropLast())
        }
        
        // Strip surrounding quotes
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2 {
            return String(trimmed.dropFirst().dropLast())
        }
        
        // Strip array brackets []
        if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
            let inner = String(trimmed.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
            if inner.isEmpty { return "" }
            // Return as-is for array, will be processed separately
            return inner
        }
        
        return trimmed
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
