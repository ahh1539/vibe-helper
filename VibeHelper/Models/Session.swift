import Foundation

struct SessionModelConfig: Codable {
    let name: String
    let provider: String
    let alias: String?
    let temperature: Double?
    let inputPrice: Double?
    let outputPrice: Double?
}

struct SessionConfig: Codable {
    let activeModel: String
    let models: [SessionModelConfig]?
}

struct SessionAgentProfile: Codable {
    let name: String
}

struct Session: Codable, Identifiable {
    let sessionId: String
    let startTime: Date
    let endTime: Date
    let gitCommit: String?
    let gitBranch: String?
    let environment: SessionEnvironment
    let username: String
    let stats: SessionStats
    let title: String?
    let totalMessages: Int
    let config: SessionConfig?
    let agentProfile: SessionAgentProfile?
    var directoryURL: URL?

    var id: String { sessionId }

    private enum CodingKeys: String, CodingKey {
        case sessionId, startTime, endTime, gitCommit, gitBranch
        case environment, username, stats, title, totalMessages
        case config, agentProfile
    }

    var activeModelName: String {
        config?.activeModel ?? "unknown"
    }

    var agentProfileName: String? {
        guard let name = agentProfile?.name, name != "default" else { return nil }
        return name
    }

    var projectName: String {
        (environment.workingDirectory as NSString).lastPathComponent
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}

struct SessionEnvironment: Codable {
    let workingDirectory: String
}

struct SessionStats: Codable {
    let steps: Int
    let sessionPromptTokens: Int
    let sessionCompletionTokens: Int
    let toolCallsAgreed: Int
    let toolCallsRejected: Int
    let toolCallsFailed: Int
    let toolCallsSucceeded: Int
    let contextTokens: Int
    let lastTurnPromptTokens: Int
    let lastTurnCompletionTokens: Int
    let lastTurnDuration: Double
    let tokensPerSecond: Double
    let inputPricePerMillion: Double
    let outputPricePerMillion: Double
    let sessionTotalLlmTokens: Int
    let lastTurnTotalTokens: Int
    let sessionCost: Double

    var totalToolCalls: Int {
        toolCallsAgreed + toolCallsRejected + toolCallsFailed
    }

    var formattedCost: String {
        String(format: "$%.2f", sessionCost)
    }

    var formattedTokens: String {
        if sessionTotalLlmTokens >= 1_000_000 {
            return String(format: "%.1fM", Double(sessionTotalLlmTokens) / 1_000_000)
        } else if sessionTotalLlmTokens >= 1_000 {
            return String(format: "%.1fK", Double(sessionTotalLlmTokens) / 1_000)
        }
        return "\(sessionTotalLlmTokens)"
    }
}
