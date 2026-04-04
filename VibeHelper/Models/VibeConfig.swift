import Foundation

struct VibeModel: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var provider: String
    var alias: String
    var temperature: Double
    var inputPrice: Double
    var outputPrice: Double
    var thinking: String
    var autoCompactThreshold: Int
}

struct VibeProvider: Identifiable, Equatable {
    var id: String { name }
    var name: String
    var apiBase: String
    var apiKeyEnvVar: String
    var apiStyle: String
    var backend: String
    var reasoningFieldName: String
    var projectId: String
    var region: String
}

// MARK: - TOML Parsing

enum TomlParser {

    /// Parse all `[[models]]` blocks from raw TOML content.
    static func parseModels(from content: String) -> [VibeModel] {
        let blocks = extractBlocks(from: content, header: "[[models]]")
        return blocks.compactMap { block in
            let kv = parseKeyValues(block)
            guard let name = kv["name"] else { return nil }
            return VibeModel(
                name: name,
                provider: kv["provider"] ?? "",
                alias: kv["alias"] ?? "",
                temperature: Double(kv["temperature"] ?? "") ?? 0.0,
                inputPrice: Double(kv["input_price"] ?? "") ?? 0.0,
                outputPrice: Double(kv["output_price"] ?? "") ?? 0.0,
                thinking: kv["thinking"] ?? "off",
                autoCompactThreshold: Int(kv["auto_compact_threshold"] ?? "") ?? 0
            )
        }
    }

    /// Parse all `[[providers]]` blocks from raw TOML content.
    static func parseProviders(from content: String) -> [VibeProvider] {
        let blocks = extractBlocks(from: content, header: "[[providers]]")
        return blocks.compactMap { block in
            let kv = parseKeyValues(block)
            guard let name = kv["name"] else { return nil }
            return VibeProvider(
                name: name,
                apiBase: kv["api_base"] ?? "",
                apiKeyEnvVar: kv["api_key_env_var"] ?? "",
                apiStyle: kv["api_style"] ?? "",
                backend: kv["backend"] ?? "",
                reasoningFieldName: kv["reasoning_field_name"] ?? "",
                projectId: kv["project_id"] ?? "",
                region: kv["region"] ?? ""
            )
        }
    }

    /// Parse the `active_model` value from raw TOML content.
    static func parseActiveModel(from content: String) -> String {
        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("active_model") {
                return extractValue(from: trimmed)
            }
        }
        return ""
    }

    /// Serialize a single model to a TOML `[[models]]` block.
    static func serializeModel(_ model: VibeModel) -> String {
        var lines = ["[[models]]"]
        lines.append("name = \"\(model.name)\"")
        lines.append("provider = \"\(model.provider)\"")
        lines.append("alias = \"\(model.alias)\"")
        lines.append("temperature = \(model.temperature)")
        lines.append("input_price = \(model.inputPrice)")
        lines.append("output_price = \(model.outputPrice)")
        lines.append("thinking = \"\(model.thinking)\"")
        lines.append("auto_compact_threshold = \(model.autoCompactThreshold)")
        return lines.joined(separator: "\n")
    }

    /// Serialize a single provider to a TOML `[[providers]]` block.
    static func serializeProvider(_ provider: VibeProvider) -> String {
        var lines = ["[[providers]]"]
        lines.append("name = \"\(provider.name)\"")
        lines.append("api_base = \"\(provider.apiBase)\"")
        lines.append("api_key_env_var = \"\(provider.apiKeyEnvVar)\"")
        lines.append("api_style = \"\(provider.apiStyle)\"")
        lines.append("backend = \"\(provider.backend)\"")
        if !provider.reasoningFieldName.isEmpty {
            lines.append("reasoning_field_name = \"\(provider.reasoningFieldName)\"")
        }
        if !provider.projectId.isEmpty {
            lines.append("project_id = \"\(provider.projectId)\"")
        }
        if !provider.region.isEmpty {
            lines.append("region = \"\(provider.region)\"")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Block Extraction

    /// Extract all content blocks for a given `[[header]]` type.
    /// Each block is the text between the header and the next section header.
    static func extractBlocks(from content: String, header: String) -> [String] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [String] = []
        var currentBlock: [String]? = nil

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == header {
                // Save previous block if any
                if let block = currentBlock {
                    blocks.append(block.joined(separator: "\n"))
                }
                currentBlock = []
            } else if trimmed.hasPrefix("[[") || (trimmed.hasPrefix("[") && !trimmed.hasPrefix("[[")) {
                // Hit a new section — close current block
                if let block = currentBlock {
                    blocks.append(block.joined(separator: "\n"))
                    currentBlock = nil
                }
            } else if currentBlock != nil {
                currentBlock?.append(line)
            }
        }

        // Don't forget the last block
        if let block = currentBlock {
            blocks.append(block.joined(separator: "\n"))
        }

        return blocks
    }

    /// Find the byte range of a specific block (by matching `name = "value"` inside it)
    /// so we can do targeted replacement in the raw file content.
    static func findBlockRange(in content: String, header: String, matchingName name: String) -> Range<String.Index>? {
        let lines = content.components(separatedBy: "\n")
        var blockStart: String.Index? = nil
        var searchIndex = content.startIndex

        for line in lines {
            guard let lineRange = content.range(of: line + "\n", range: searchIndex..<content.endIndex)
                    ?? content.range(of: line, range: searchIndex..<content.endIndex) else {
                continue
            }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed == header {
                blockStart = lineRange.lowerBound
            } else if blockStart != nil && (trimmed.hasPrefix("[[") || (trimmed.hasPrefix("[") && !trimmed.hasPrefix("[["))) {
                // End of block — check if this was the right one
                if let start = blockStart {
                    let blockContent = String(content[start..<lineRange.lowerBound])
                    if blockContent.contains("name = \"\(name)\"") {
                        return start..<lineRange.lowerBound
                    }
                }
                blockStart = trimmed == header ? lineRange.lowerBound : nil
            }

            searchIndex = lineRange.upperBound
        }

        // Check last block (at end of file)
        if let start = blockStart {
            let blockContent = String(content[start..<content.endIndex])
            if blockContent.contains("name = \"\(name)\"") {
                return start..<content.endIndex
            }
        }

        return nil
    }

    // MARK: - Key-Value Parsing

    private static func parseKeyValues(_ block: String) -> [String: String] {
        var result: [String: String] = [:]
        for line in block.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#"), !trimmed.hasPrefix("[") else { continue }
            guard let eqIndex = trimmed.firstIndex(of: "=") else { continue }
            let key = String(trimmed[..<eqIndex]).trimmingCharacters(in: .whitespaces)
            let value = extractValue(from: String(trimmed[trimmed.index(after: eqIndex)...]))
            result[key] = value
        }
        return result
    }

    private static func extractValue(from raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        // Strip surrounding quotes
        if trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"") && trimmed.count >= 2 {
            return String(trimmed.dropFirst().dropLast())
        }
        return trimmed
    }
}
