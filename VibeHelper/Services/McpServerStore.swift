import Foundation
import SwiftUI

@MainActor
final class McpServerStore: ObservableObject {
    @Published var servers: [McpServer] = []
    @Published var isLoading = false
    @Published var lastError: String? = nil
    
    private let configStore = ConfigStore()
    
    private func findServer(byId id: UUID) -> McpServer? {
        servers.first { $0.id == id }
    }
    
    private func findServer(byName name: String) -> McpServer? {
        servers.first { $0.name.lowercased() == name.lowercased() }
    }
    
    // MARK: - Lifecycle
    
    func load() async {
        isLoading = true
        lastError = nil
        
        // Use ConfigStore which maintains rawContent
        await configStore.load()
        
        // Parse from raw content
        let parsedServers = TomlMcpParser.parseMcpServers(from: configStore.rawContent)
        servers = parsedServers
        
isLoading = false
    }
    
    // MARK: - CRUD Operations with Safety
    
    func addServer(_ server: McpServer) async {
        var updated = servers
        updated.append(server)
        
        do {
            try await saveServers(updated)
            await load() // Refresh from disk
        } catch {
            lastError = "Failed to add server: \(error.localizedDescription)"
        }
    }
    
    func updateServer(_ server: McpServer) async {
        let updated = servers.map { current in
            current.name.lowercased() == server.name.lowercased() ? server : current
        }
        
        do {
            try await saveServers(updated)
            await load()
        } catch {
            lastError = "Failed to update server: \(error.localizedDescription)"
        }
    }
    
    func deleteServer(_ server: McpServer) async {
        let updated = servers.filter { $0.name.lowercased() != server.name.lowercased() }
        
        // Confirmation could be here, but we delegate to UI
        do {
            try await saveServers(updated)
            await load()
        } catch {
            lastError = "Failed to save: \(error.localizedDescription)"
        }
    }
    
    func toggleServer(_ server: McpServer, enabled: Bool) async {
        var updated = server
        updated.isEnabled = enabled
        
        // Fast local toggle doesn't persist (UX optimization)
        // When they navigate away, it will reflect persistence
        // For now, let's update persistently to be safe
        do {
            try await saveServers(servers.map { 
                $0.name.lowercased() == server.name.lowercased() ? updated : $0 
            })
            await load()
        } catch {
            lastError = "Failed to toggle: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Batch Operations
    
    func enableAllServers() async {
        let updated = servers.map { var server = $0; server.isEnabled = true; return server }
        
        do {
            try await saveServers(updated)
            await load()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    func disableAllServers() async {
        let updated = servers.map { var server = $0; server.isEnabled = false; return server }
        
        do {
            try await saveServers(updated)
            await load()
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    // MARK: - Internal Helper Methods
    
    private func saveServers(_ servers: [McpServer]) async throws {
        // Create full updated configuration by adding MCP servers back to existing content
        var effectiveContent = ""
        
        // Read current config to preserve other sections
        if FileManager.default.fileExists(atPath: ConfigStore.configFile.path) {
            effectiveContent = try String(contentsOf: ConfigStore.configFile, encoding: .utf8)
        }
        
        // Remove existing MCP server sections
        var cleanedContent = effectiveContent
        cleanedContent = cleanTomlContent(cleanedContent, removeMcpServers: true)
        
        // Update content: effective content + new serialized servers
        cleanedContent += "\n\n"
        cleanedContent += servers.map { TomlMcpParser.serializeMcpServer($0) }.joined(separator: "\n\n")
        
        // Safe write using ConfigStore infrastructure
        try await configStore.writeMcpServersContent(cleanedContent, servers: servers)
    }
    
    func refreshFromDisk() async {
        await load()
    }
    
    // MARK: - Configuration Preservation
    
    func getCurrentConfigContent() async -> String {
        await configStore.load()
        return configStore.rawContent
    }
    
    func serverExists(named name: String, excluding existingServer: McpServer? = nil) -> Bool {
        if let existing = existingServer {
            return servers.contains { 
                $0.name.lowercased() == name.lowercased() && $0.name.lowercased() != existing.name.lowercased()
            }
        }
        return servers.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    // MARK: - Configuration Backup Management
    
    func getTimestampedBackups() async -> [ConfigBackup] {
        await configStore.load()
        return configStore.backups
    }
    
    private func cleanTomlContent(_ content: String, removeMcpServers: Bool = true) -> String {
        var result = content
        
        if removeMcpServers {
            // Split by [[mcp_servers]], keep first part only (others removed)
            result = result.components(separatedBy: "[[mcp_servers]]").first ?? ""
        }
        
        return result
    }
}
