import SwiftUI

struct SkillsListView: View {
    @StateObject private var store = SkillStore()
    @State private var showingNewSkill = false
    @State private var selectedSkill: Skill? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Toolbar
                HStack {
                    Text("Skills")
                        .font(.title2.weight(.bold))

                    Spacer()

                    Button { showingNewSkill = true } label: {
                        Label("New Skill", systemImage: "plus")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.vibePrimary)

                    Button {
                        Task { await store.load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .help("Refresh")
                }
                .padding(.horizontal, 4)

                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.skills.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No Skills Found")
                            .font(.headline)
                        Text("Skills live in ~/.vibe/skills/ as directories with a SKILL.md file.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Create Your First Skill") { showingNewSkill = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 60)
                } else {
                    ForEach(store.skills) { skill in
                        SkillRow(skill: skill, isEnabled: store.isEnabled(skill))
                            .onTapGesture { selectedSkill = skill }
                    }
                }
            }
            .padding(20)
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
        .task {
            await store.load()
            store.startWatching()
        }
        .sheet(item: $selectedSkill) { skill in
            SkillDetailView(skill: skill, store: store)
        }
        .sheet(isPresented: $showingNewSkill) {
            SkillEditorView(mode: .create, store: store)
        }
    }
}

private struct SkillRow: View {
    let skill: Skill
    let isEnabled: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: skill.frontmatter.userInvocable ? "terminal" : "gearshape")
                .font(.title3)
                .foregroundStyle(Color.vibePrimary)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(skill.frontmatter.name)
                    .font(.body.weight(.medium))
                Text(skill.frontmatter.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(skill.frontmatter.tools, id: \.self) { tool in
                    Text(tool)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.vibeAccent.opacity(0.1))
                        .foregroundStyle(Color.vibeAccent)
                        .clipShape(Capsule())
                }
            }

            Text(isEnabled ? "Enabled" : "Disabled")
                .font(.caption.weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(isEnabled ? Color.vibeSuccess.opacity(0.1) : Color.subtleText.opacity(0.1))
                .foregroundStyle(isEnabled ? Color.vibeSuccess : Color.subtleText)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .cardStyle()
    }
}
