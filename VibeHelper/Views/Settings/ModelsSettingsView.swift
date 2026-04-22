import SwiftUI

struct ModelsSettingsView: View {
    @StateObject private var store = ConfigStore()
    @State private var selectedModel: VibeModel? = nil
    @State private var selectedProvider: VibeProvider? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Toolbar
                HStack {
                    Text("Models & Providers")
                        .font(.title2.weight(.bold))
                    Spacer()
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
                } else {
                    // Models
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Models")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(store.models) { model in
                            ModelRow(model: model)
                                .onTapGesture { selectedModel = model }
                        }
                    }
                    .cardStyle()

                    // Providers
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Providers")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ForEach(store.providers) { provider in
                            ProviderRow(provider: provider)
                                .onTapGesture { selectedProvider = provider }
                        }
                    }
                    .cardStyle()

                    // Backups
                    BackupsSection(store: store)
                    
                    // MCP Servers
                    McpServersSettingsView()
                        .cardStyle()
                }

                if let error = store.lastError {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.vibeDanger)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.vibeDanger)
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
        .sheet(item: $selectedModel) { model in
            ModelEditorView(model: model, store: store)
        }
        .sheet(item: $selectedProvider) { provider in
            ProviderEditorView(provider: provider, store: store)
        }
    }
}

// MARK: - Backups Section

private struct BackupsSection: View {
    @ObservedObject var store: ConfigStore
    @State private var restoreError: String? = nil
    @State private var confirmRestore: ConfigBackup? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Backups")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if store.backups.isEmpty {
                Text("No backups yet — a backup is created automatically before each save")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 8)
            } else {
                ForEach(store.backups.prefix(10)) { backup in
                    HStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(backup.date.shortFormatted)
                                .font(.body)
                            Text(backup.id)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Button("Restore") {
                            confirmRestore = backup
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.vibePrimary)
                        .font(.callout)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                }
            }

            if let error = restoreError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(Color.vibeDanger)
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Color.vibeDanger)
                }
            }
        }
        .cardStyle()
        .alert("Restore Backup?", isPresented: Binding(
            get: { confirmRestore != nil },
            set: { if !$0 { confirmRestore = nil } }
        )) {
            Button("Restore", role: .destructive) {
                guard let backup = confirmRestore else { return }
                do {
                    try store.restoreBackup(backup)
                    restoreError = nil
                } catch {
                    restoreError = error.localizedDescription
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will replace your current config.toml with the backup. A new backup of the current config will be created first.")
        }
    }
}

// MARK: - Model Row

private struct ModelRow: View {
    let model: VibeModel

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.alias.isEmpty ? model.name : model.alias)
                    .font(.body.weight(.medium))
                if !model.alias.isEmpty {
                    Text(model.name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Provider pill
            Text(model.provider)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.vibePrimary.opacity(0.1))
                .foregroundStyle(Color.vibePrimary)
                .clipShape(Capsule())

            // Thinking pill
            Text(model.thinking)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.vibeAccent.opacity(0.1))
                .foregroundStyle(Color.vibeAccent)
                .clipShape(Capsule())

            // Temperature
            Text(String(format: "T: %.1f", model.temperature))
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(width: 45, alignment: .trailing)

            // Price
            Text(String(format: "$%.2f/$%.2f", model.inputPrice, model.outputPrice))
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(Color.vibeAccent)
                .frame(width: 90, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}

// MARK: - Provider Row

private struct ProviderRow: View {
    let provider: VibeProvider

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(provider.name)
                    .font(.body.weight(.medium))
                Text(provider.apiBase)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(provider.apiStyle)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.vibePrimary.opacity(0.1))
                .foregroundStyle(Color.vibePrimary)
                .clipShape(Capsule())

            Text(provider.backend)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.vibeAccent.opacity(0.1))
                .foregroundStyle(Color.vibeAccent)
                .clipShape(Capsule())

            if !provider.apiKeyEnvVar.isEmpty {
                Image(systemName: "key.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help(provider.apiKeyEnvVar)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}
