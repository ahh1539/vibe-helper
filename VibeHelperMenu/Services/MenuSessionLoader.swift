import Foundation

/// Lightweight session loader for menu bar app
/// Only loads essential fields: sessionId, startTime, sessionCost, sessionTotalLlmTokens
final class MenuSessionLoader {
    
    static let sessionDirectory: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".vibe/logs/session")
    }()
    
    /// Load all sessions from the session directory
    /// Only parses meta.json files and extracts minimal data
    static func loadAllSessions() async -> [MenuSession] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let sessions = loadSessionsSync()
                continuation.resume(returning: sessions)
            }
        }
    }
    
    private static func loadSessionsSync() -> [MenuSession] {
        guard let enumerator = FileManager.default.enumerator(at: sessionDirectory, 
                                 includingPropertiesForKeys: [.isDirectoryKey],
                                 options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }
        
        var sessions: [MenuSession] = []
        
        for case let fileURL as URL in enumerator {
            guard fileURL.lastPathComponent == "meta.json",
                  let data = try? Data(contentsOf: fileURL),
                  let session = try? decodeSession(from: data) else {
                continue
            }
            sessions.append(session)
        }
        
        return sessions.sorted { $0.startTime > $1.startTime }
    }
    
    /// Decode only the fields we need from meta.json
    /// Uses a wrapper type to parse partial JSON
    private static func decodeSession(from data: Data) throws -> MenuSession {
        // First try full decode
        if let session = try? JSONDecoder().decode(MenuSession.self, from: data) {
            return session
        }
        
        // Fallback: parse with a more permissive approach
        // meta.json has many fields we don't need, so we parse it as a dictionary
        // and extract only what we need
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        guard let sessionId = json?["sessionId"] as? String,
              let startTimeString = json?["startTime"] as? String,
              let startTime = ISO8601DateFormatter().date(from: startTimeString),
              let statsDict = json?["stats"] as? [String: Any] else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: [], debugDescription: "Missing required fields")
            )
        }
        
        let sessionCost = statsDict["sessionCost"] as? Double ?? 0
        let sessionTotalLlmTokens = statsDict["sessionTotalLlmTokens"] as? Int ?? 0
        
        let stats = MenuSessionStats(
            sessionCost: sessionCost,
            sessionTotalLlmTokens: sessionTotalLlmTokens
        )
        
        return MenuSession(sessionId: sessionId, startTime: startTime, stats: stats)
    }
}
