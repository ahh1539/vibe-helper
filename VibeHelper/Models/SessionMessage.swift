import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
    case tool
}

struct ToolFunction: Codable {
    let name: String
    let arguments: String
}

struct ToolCall: Identifiable, Codable {
    let id: String
    let type: String
    let function: ToolFunction
    let index: Int?
}

struct SessionMessage: Identifiable, Codable {
    let id: String
    let role: MessageRole
    let content: String?
    let messageId: String?
    let toolCalls: [ToolCall]?
    let name: String?
    let toolCallId: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        role = try container.decode(MessageRole.self, forKey: .role)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        messageId = try container.decodeIfPresent(String.self, forKey: .messageId)
        toolCalls = try container.decodeIfPresent([ToolCall].self, forKey: .toolCalls)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        toolCallId = try container.decodeIfPresent(String.self, forKey: .toolCallId)
        id = messageId ?? toolCallId ?? UUID().uuidString
    }
}
