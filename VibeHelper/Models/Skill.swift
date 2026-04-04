import Foundation

struct SkillFrontmatter: Equatable {
    var name: String
    var description: String
    var userInvocable: Bool
    var tools: [String]
}

struct Skill: Identifiable, Equatable {
    let id: String
    var frontmatter: SkillFrontmatter
    var body: String
    var directoryURL: URL

    var skillFileURL: URL {
        directoryURL.appendingPathComponent("SKILL.md")
    }

    static func parse(fileContent: String, directoryName: String, directoryURL: URL) throws -> Skill {
        let content = fileContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard content.hasPrefix("---") else { throw SkillParseError.noFrontmatter }

        let afterFirstDelimiter = String(content.dropFirst(3))
        guard let endRange = afterFirstDelimiter.range(of: "\n---") else {
            throw SkillParseError.noFrontmatter
        }

        let yaml = String(afterFirstDelimiter[..<endRange.lowerBound])
        let bodyStart = afterFirstDelimiter.index(endRange.upperBound, offsetBy: 0)
        let body = String(afterFirstDelimiter[bodyStart...]).trimmingCharacters(in: .newlines)

        let frontmatter = try parseFrontmatter(yaml)
        return Skill(
            id: directoryName,
            frontmatter: frontmatter,
            body: body,
            directoryURL: directoryURL
        )
    }

    static func serialize(_ skill: Skill) -> String {
        var lines = ["---"]
        lines.append("name: \(skill.frontmatter.name)")
        lines.append("description: \(skill.frontmatter.description)")
        lines.append("user-invocable: \(skill.frontmatter.userInvocable)")
        if !skill.frontmatter.tools.isEmpty {
            lines.append("tools:")
            for tool in skill.frontmatter.tools {
                lines.append("  - \(tool)")
            }
        }
        lines.append("---")
        return lines.joined(separator: "\n") + "\n" + skill.body + "\n"
    }

    private static func parseFrontmatter(_ yaml: String) throws -> SkillFrontmatter {
        var name = ""
        var description = ""
        var userInvocable = false
        var tools: [String] = []
        var inToolsList = false

        for line in yaml.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("- ") && inToolsList {
                tools.append(String(trimmed.dropFirst(2)))
                continue
            }
            inToolsList = false

            guard let colonIndex = trimmed.firstIndex(of: ":") else { continue }
            let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

            switch key {
            case "name": name = value
            case "description": description = value
            case "user-invocable": userInvocable = (value == "true")
            case "tools":
                if value.isEmpty {
                    inToolsList = true
                }
            default: break
            }
        }

        guard !name.isEmpty else { throw SkillParseError.missingRequiredField("name") }
        return SkillFrontmatter(name: name, description: description, userInvocable: userInvocable, tools: tools)
    }
}

enum SkillParseError: Error {
    case noFrontmatter
    case missingRequiredField(String)
}
