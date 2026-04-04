import SwiftUI

enum SkillEditorMode {
    case create
    case edit(Skill)
}

struct SkillEditorView: View {
    let mode: SkillEditorMode
    @ObservedObject var store: SkillStore
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var skillDescription: String = ""
    @State private var userInvocable: Bool = true
    @State private var selectedTools: Set<String> = ["bash"]
    @State private var instructions: String = ""
    @State private var errorMessage: String? = nil

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var directoryName: String {
        name.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .filter { $0.isLetter || $0.isNumber || $0 == "-" }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isEditing ? "Edit Skill" : "New Skill")
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("my-skill", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isEditing)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("What this skill does", text: $skillDescription)
                            .textFieldStyle(.roundedBorder)
                    }

                    Toggle("User Invocable", isOn: $userInvocable)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Allowed Tools")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if store.availableTools.isEmpty {
                            Text("No tools found in config.toml")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                                ForEach(store.availableTools, id: \.self) { tool in
                                    ToolToggle(
                                        tool: tool,
                                        isSelected: selectedTools.contains(tool),
                                        action: {
                                            if selectedTools.contains(tool) {
                                                selectedTools.remove(tool)
                                            } else {
                                                selectedTools.insert(tool)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Instructions (Markdown)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $instructions)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 200)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                .padding()
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.vibeDanger)
                    .padding(.horizontal)
            }

            Divider()

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(isEditing ? "Save" : "Create") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
        .onAppear {
            if case .edit(let skill) = mode {
                name = skill.frontmatter.name
                skillDescription = skill.frontmatter.description
                userInvocable = skill.frontmatter.userInvocable
                selectedTools = Set(skill.frontmatter.tools)
                instructions = skill.body
            }
        }
    }

    private func save() {
        let tools = selectedTools.sorted()
        let frontmatter = SkillFrontmatter(
            name: name,
            description: skillDescription,
            userInvocable: userInvocable,
            tools: tools
        )

        do {
            switch mode {
            case .create:
                let dirURL = SkillStore.skillsDirectory.appendingPathComponent(directoryName)
                let skill = Skill(id: directoryName, frontmatter: frontmatter, body: instructions, directoryURL: dirURL)
                try store.createSkill(skill)
            case .edit(let existing):
                var updated = existing
                updated.frontmatter = frontmatter
                updated.body = instructions
                try store.updateSkill(updated)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct ToolToggle: View {
    let tool: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.vibePrimary : .secondary)
                Text(tool)
                    .font(.callout)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.vibePrimary.opacity(0.08) : Color.primary.opacity(0.03))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.vibePrimary.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
