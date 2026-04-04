import SwiftUI

struct SkillDetailView: View {
    let skill: Skill
    @ObservedObject var store: SkillStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(skill.frontmatter.name)
                            .font(.title2.weight(.semibold))
                        Text(skill.frontmatter.description)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()

                    Button { showingEditor = true } label: {
                        Label("Edit", systemImage: "pencil")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.vibePrimary)

                    Button { showingDeleteConfirmation = true } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.callout)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.vibeDanger)

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Divider()

                // Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    StatBox(
                        title: "User Invocable",
                        value: skill.frontmatter.userInvocable ? "Yes" : "No",
                        color: .vibePrimary
                    )
                    StatBox(
                        title: "Tools",
                        value: "\(skill.frontmatter.tools.count)",
                        color: .vibeAccent
                    )
                    StatBox(
                        title: "Status",
                        value: store.isEnabled(skill) ? "Enabled" : "Disabled",
                        color: store.isEnabled(skill) ? .vibeSuccess : .subtleText
                    )
                }

                Divider()

                // Tools
                if !skill.frontmatter.tools.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Allowed Tools")
                            .font(.headline)
                        HStack(spacing: 6) {
                            ForEach(skill.frontmatter.tools, id: \.self) { tool in
                                Text(tool)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.vibeAccent.opacity(0.1))
                                    .foregroundStyle(Color.vibeAccent)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    Divider()
                }

                // Body
                VStack(alignment: .leading, spacing: 8) {
                    Text("Skill Instructions")
                        .font(.headline)
                    Text(skill.body)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.primary.opacity(0.03))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(24)
        }
        .frame(minWidth: 600, minHeight: 500)
        .sheet(isPresented: $showingEditor) {
            SkillEditorView(mode: .edit(skill), store: store)
        }
        .alert("Delete Skill?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                try? store.deleteSkill(skill)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the \"\(skill.frontmatter.name)\" skill directory.")
        }
    }
}
