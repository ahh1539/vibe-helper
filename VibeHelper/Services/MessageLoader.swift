import Foundation

struct MessageLoader {
    static func load(directoryURL: URL) async -> [SessionMessage] {
        await Task.detached(priority: .userInitiated) {
            let url = directoryURL.appendingPathComponent("messages.jsonl")
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            var messages: [SessionMessage] = []
            do {
                for try await line in url.lines {
                    guard !line.isEmpty else { continue }
                    guard let data = line.data(using: .utf8) else { continue }
                    if let message = try? decoder.decode(SessionMessage.self, from: data) {
                        messages.append(message)
                    }
                }
            } catch {
                // Silently skip unreadable messages
            }
            return messages
        }.value
    }
}
