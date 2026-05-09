import Foundation
import SwiftUI

@MainActor
final class McpServerStore: ObservableObject {
    @Published var servers: [McpServer] = []
    @Published var isLoading = false
    @Published var lastError: String? = nil
    
    // Use shared ConfigStore to avoid stale state and write conflicts
    private var configStore: ConfigStore { StoresContainer.shared.configStore }
    
    private func findServer(byId id: UUID) -> McpServer? {
        servers.first { $0.id == id }
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
            current.id == server.id ? server : current
        }
        
        do {
            try await saveServers(updated)
            await load()
        } catch {
            lastError = "Failed to update server: \(error.localizedDescription)"
        }
    }
    
    func deleteServer(_ server: McpServer) async {
        let updated = servers.filter { $0.id != server.id }
        
        // Confirmation is handled by UI via alert
        do {
            try await saveServers(updated)
            await load()
        } catch {
            lastError = "Failed to delete server: \(error.localizedDescription)"
        }
    }
    
    func toggleServer(_ server: McpServer, enabled: Bool) async {
        var updated = server
        updated.isEnabled = enabled
        
        do {
            try await saveServers(servers.map { 
                $0.id == server.id ? updated : $0 
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
        // Use the shared configStore's rawContent to preserve all other sections
        await configStore.load()
        var effectiveContent = configStore.rawContent
        
        // Remove existing MCP server sections
        let cleanedContent = cleanTomlContent(effectiveContent, removeMcpServers: true)
        
        // Update content: cleaned content + new serialized servers
        var updatedContent = cleanedContent
        if !cleanedContent.isEmpty {
            updatedContent += "\n\n"
        }
        updatedContent += servers.map { TomlMcpParser.serializeMcpServer($0) }.joined(separator: "\n\n")
        
        // Safe write using ConfigStore infrastructure
        try await configStore.writeMcpServersContent(updatedContent, servers: servers)
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
                $0.name.lowercased() == name.lowercased() && $0.id != existing.id
            }
        }
        return servers.contains { $0.name.lowercased() == name.lowercased() }
    }
    
    func getServer(byId id: UUID) -> McpServer? {
        servers.first { $0.id == id }
    }
    
    // MARK: - Configuration Backup Management
    
    func getTimestampedBackups() async -> [ConfigBackup] {
        await configStore.load()
        return configStore.backups
    }
    
    /// Removes all MCP server blocks from TOML content while preserving all other sections
    /// This prevents data loss when models/providers appear after MCP servers
    private func cleanTomlContent(_ content: String, removeMcpServers: Bool = true) -> String {
        guard removeMcpServers else { return content }
        
        let lines = content.components(separatedBy: .newlines)
        var result: [String] = []
        var inMcpServerBlock = false
        var mcpBlockDepth = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Track when we enter/exit MCP server blocks
            if trimmed == "[[mcp_servers]]" {
                inMcpServerBlock = true
                mcpBlockDepth = 1
                continue // Skip this line
            }
            
            // Decrement depth when we exit a block (any [[...]] section)
            if trimmed.hasPrefix("[[") && trimmed.hasSuffix("]]") && inMcpServerBlock {
                mcpBlockDepth -= 1
                if mcpBlockDepth == 0 {
                    inMcpServerBlock = false
                }
                continue // Skip section header lines within MCP blocks
            }
            
            // If we're inside an MCP server block, skip the line
            if inMcpServerBlock {
                continue
            }
            
            result.append(line)
        }
        
        return result.joined(separator: "\n")
    }
}
