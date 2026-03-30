import Foundation

struct MessageLoader {
    static func load(directoryURL: URL) async -> [SessionMessage] {
        await Task.detached(priority: .userInitiated) {
            let url = directoryURL.appendingPathComponent("messages.jsonl")
            do {
                let data = try Data(contentsOf: url)
                guard let text = String(data: data, encoding: .utf8) else { return [] }
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                return text.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty }
                    .compactMap { line -> SessionMessage? in
                        guard let d = line.data(using: .utf8) else { return nil }
                        return try? decoder.decode(SessionMessage.self, from: d)
                    }
            } catch {
                print("MessageLoader: Failed to load messages: \(error)")
                return []
            }
        }.value
    }
}
