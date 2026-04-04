import Foundation
import SwiftUI

@MainActor
final class SkillStore: ObservableObject {
    @Published var skills: [Skill] = []
    @Published var isLoading = false
    @Published var enabledSkillNames: Set<String> = []
    @Published var disabledSkillNames: Set<String> = []
    @Published var availableTools: [String] = SkillStore.defaultTools

    private var fileWatcher: FileWatcher?

    static let skillsDirectory = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/skills")

    static let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/config.toml")

    static let defaultTools = [
        "ask_user_question",
        "bash",
        "exit_plan_mode",
        "grep",
        "read_file",
        "search_replace",
        "task",
        "todo",
        "web_fetch",
        "web_search",
        "write_file",
    ]

    func load() async {
        isLoading = true
        skills = Self.loadAllSkills()
        loadConfig()
        isLoading = false
    }

    private static func loadAllSkills() -> [Skill] {
        let fm = FileManager.default
        let baseURL = skillsDirectory

        guard let contents = try? fm.contentsOfDirectory(
            at: baseURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var result: [Skill] = []
        for url in contents {
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue else { continue }
            let skillFile = url.appendingPathComponent("SKILL.md")
            guard let content = try? String(contentsOf: skillFile, encoding: .utf8) else { continue }
            let dirName = url.lastPathComponent
            if let skill = try? Skill.parse(fileContent: content, directoryName: dirName, directoryURL: url) {
                result.append(skill)
            }
        }
        return result.sorted { $0.frontmatter.name < $1.frontmatter.name }
    }

    private func loadConfig() {
        guard let content = try? String(contentsOf: Self.configFile, encoding: .utf8) else { return }
        enabledSkillNames = Self.parseTomlArray(content, key: "enabled_skills")
        disabledSkillNames = Self.parseTomlArray(content, key: "disabled_skills")
        let configTools = Self.parseToolSections(content)
        if !configTools.isEmpty {
            availableTools = Array(Set(Self.defaultTools + configTools)).sorted()
        }
    }

    private static func parseToolSections(_ content: String) -> [String] {
        let pattern = #"\[tools\.([^\]]+)\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex.matches(in: content, range: range)
        let tools = matches.compactMap { match -> String? in
            guard let captureRange = Range(match.range(at: 1), in: content) else { return nil }
            return String(content[captureRange])
        }
        return tools.sorted()
    }

    private static func parseTomlArray(_ content: String, key: String) -> Set<String> {
        guard let line = content.components(separatedBy: "\n")
            .first(where: { $0.hasPrefix("\(key) ") || $0.hasPrefix("\(key)=") })
        else { return [] }

        guard let openBracket = line.firstIndex(of: "["),
              let closeBracket = line.firstIndex(of: "]")
        else { return [] }

        let inner = line[line.index(after: openBracket)..<closeBracket]
        let items = inner.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"")) }
            .filter { !$0.isEmpty }
        return Set(items)
    }

    func isEnabled(_ skill: Skill) -> Bool {
        if disabledSkillNames.contains(skill.id) { return false }
        if enabledSkillNames.isEmpty { return true }
        return enabledSkillNames.contains(skill.id)
    }

    func createSkill(_ skill: Skill) throws {
        let fm = FileManager.default
        try fm.createDirectory(at: skill.directoryURL, withIntermediateDirectories: true)
        let content = Skill.serialize(skill)
        try content.write(to: skill.skillFileURL, atomically: true, encoding: .utf8)
        Task { await load() }
    }

    func updateSkill(_ skill: Skill) throws {
        let content = Skill.serialize(skill)
        try content.write(to: skill.skillFileURL, atomically: true, encoding: .utf8)
        Task { await load() }
    }

    func deleteSkill(_ skill: Skill) throws {
        try FileManager.default.removeItem(at: skill.directoryURL)
        Task { await load() }
    }

    func startWatching() {
        fileWatcher = FileWatcher(path: Self.skillsDirectory.path) { [weak self] in
            Task { @MainActor in
                await self?.load()
            }
        }
        fileWatcher?.start()
    }

    func stopWatching() {
        fileWatcher?.stop()
    }
}
