import Foundation

/// Model representing an MCP server configuration
struct McpServer: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String = ""
    var transport: String = "stdio" // "stdio", "http", "sse", "streamablehttp"
    var url: String = ""
    var command: String = "" // For stdio transport
    var args: [String] = [] // For stdio transport
    var env: [String: String] = [:]
    var headers: [String: String] = [:]
    var apiKeyEnv: String = "" // Environment variable name for API key (empty if no auth)
    var apiKeyHeader: String = "" // Header name for API key authentication
    var apiKeyFormat: String = "" // Format string for API key, e.g., "Bearer {token}"
    var timeout: Int = 30 // Legacy field, kept for backward compatibility
    var startupTimeoutSec: Int = 15 // Timeout for server startup in seconds
    var toolTimeoutSec: Int = 120 // Timeout for tool execution in seconds
    var isEnabled: Bool = true
    
    static func == (lhs: McpServer, rhs: McpServer) -> Bool {
        lhs.id == rhs.id
    }
}

/// Helper for external configuration file references
struct McpExternalConfig: Codable {
    var configFile: String // Path to external MCP config file
    var isEnabled: Bool
}
