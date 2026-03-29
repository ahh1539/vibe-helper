import Foundation

struct SessionLoader {
    static let sessionDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/logs/session")

    static func loadAllSessions() async -> [Session] {
        let fileManager = FileManager.default
        let baseURL = sessionDirectory

        guard let contents = try? fileManager.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = formatter.date(from: dateString) {
                return date
            }
            if let date = fallbackFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date: \(dateString)"
            )
        }

        var sessions: [Session] = []

        for url in contents {
            let metaURL = url.appendingPathComponent("meta.json")
            guard fileManager.fileExists(atPath: metaURL.path) else { continue }

            do {
                let data = try Data(contentsOf: metaURL)
                let session = try decoder.decode(Session.self, from: data)
                sessions.append(session)
            } catch {
                print("Failed to parse \(metaURL.path): \(error)")
            }
        }

        return sessions.sorted { $0.startTime > $1.startTime }
    }
}
