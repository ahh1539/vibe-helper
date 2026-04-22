# MCP Server Management Implementation Plan

**Goal:** Add MCP server management UI with CRUD operations, TOML configuration integration, and automatic backups

**Architecture:** Full TOML integration with atomic writes, automatic backups, and Skills-like UI pattern

**Tech Stack:** Swift, SwiftUI, TOML parsing, FileManager for atomic operations

---

### Task 1: Create MCP Server Model

**Files:**
- Create: `VibeHelper/Models/McpServer.swift`

- [ ] **Step 1: Write the MCP Server model

```swift
import Foundation

struct McpServer: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var transport: String
    var url: String
    var headers: [String: String]
    var apiKeyEnv: String
    var isEnabled: Bool = true

    static func == (lhs: McpServer, rhs: McpServer) -> Bool {
        lhs.id == rhs.id
    }
}

struct McpConfig: Codable {
    var servers: [McpServer]
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Models/McpServer.swift
git commit -m "feat: add MCP server model"
```

---

### Task 2: Create TOML Parser with Backup System

**Files:**
- Create: `VibeHelper/Services/TomlParser.swift`

- [ ] **Step 1: Write TOML parser with backup functionality

```swift
import Foundation

enum TomlError: Error {
    case parseError(String)
    case writeError(String)
    case backupError(String)
}

final class TomlParser {
    static let configFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".vibe/config.toml")

    static func parseMcpServers() throws -> [McpServer] {
        guard let data = try? Data(contentsOf: configFile),
              let content = String(data: data, encoding: .utf8) else {
            return []
        }

        // Parse TOML content to extract mcp_servers
        // This is a simplified parser - in production use a proper TOML library
        let pattern = #"\[\[mcp_servers\]\]\s*name\s*=\s*"([^"]+)"\s*transport\s*=\s*"([^"]+)"\s*url\s*=\s*"([^"]+)"\s*headers\s*=\s*\{([^}]+)"\s*api_key_env\s*=\s*"([^"]+)"#"

        let regex = try NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

        return matches.compactMap { match in
            guard match.numberOfRanges == 6 else { return nil }

            let nameRange = match.range(at: 1)
            let transportRange = match.range(at: 2)
            let urlRange = match.range(at: 3)
            let headersRange = match.range(at: 4)
            let apiKeyEnvRange = match.range(at: 5)

            guard let name = Range(nameRange, in: content),
                  let transport = Range(transportRange, in: content),
                  let url = Range(urlRange, in: content),
                  let headers = Range(headersRange, in: content),
                  let apiKeyEnv = Range(apiKeyEnvRange, in: content) else {
                return nil
            }

            // Parse headers (simplified)
            var headersDict = [String: String]()
            let headerPairs = String(content[headers]).split(separator: ",")
            for pair in headerPairs {
                let parts = pair.split(separator: "=")
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\"", with: "")
                    headersDict[key] = value
                }
            }

            return McpServer(
                name: String(content[name]),
                transport: String(content[transport]),
                url: String(content[url]),
                headers: headersDict,
                apiKeyEnv: String(content[apiKeyEnv])
            )
        }
    }

    static func writeMcpServers(_ servers: [McpServer]) throws {
        // Create backup
        let backupFile = configFile.appendingPathExtension("bak")
        try? FileManager.default.copyItem(at: configFile, to: backupFile)

        // Read original file
        guard var content = try? String(contentsOf: configFile, encoding: .utf8) else {
            throw TomlError.writeError("Could not read original config file")
        }

        // Remove existing mcp_servers sections
        let pattern = #"(\[\[mcp_servers\]\][^[]+)"#"
        let regex = try NSRegularExpression(pattern: pattern)
        content = regex.stringByReplacingMatches(in: content, range: NSRange(content.startIndex..., in: content), withTemplate: "")

        // Add new mcp_servers sections
        for server in servers {
            let headersString = server.headers.map { "\"\($0.key)\" = \"\($0.value)\"" }.joined(separator: ", ")
            let serverSection = """
            [[mcp_servers]]
            name = "\${server.name}"
            transport = "\${server.transport}"
            url = "\${server.url}"
            headers = { \${headersString} }
            api_key_env = "\${server.apiKeyEnv}"

            """
            content.append(serverSection)
        }

        // Write atomically
        let tempFile = configFile.appendingPathExtension("tmp")
        try content.write(to: tempFile, atomically: true, encoding: .utf8)
        try FileManager.default.replaceItemAt(configFile, withItemAt: tempFile)
        try FileManager.default.removeItem(at: tempFile)
    }

    static func restoreBackup() throws {
        let backupFile = configFile.appendingPathExtension("bak")
        guard FileManager.default.fileExists(atPath: backupFile.path) else {
            throw TomlError.backupError("No backup file found")
        }
        try FileManager.default.replaceItemAt(configFile, withItemAt: backupFile)
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Services/TomlParser.swift
git commit -m "feat: add TOML parser with backup system"
```

---

### Task 3: Create MCP Server Store

**Files:**
- Create: `VibeHelper/Services/McpServerStore.swift`

- [ ] **Step 1: Write the MCP Server Store

```swift
import Foundation
import SwiftUI

@MainActor
final class McpServerStore: ObservableObject {
    @Published var servers: [McpServer] = []
    @Published var isLoading = false
    @Published var error: String? = nil
    @Published var showingBackupRestoredAlert = false

    private var fileWatcher: FileWatcher?

    func load() async {
        isLoading = true
        do {
            servers = try TomlParser.parseMcpServers()
            error = nil
        } catch {
            self.error = "Failed to load MCP servers: \${error.localizedDescription}"
            // Attempt to restore from backup if main file is corrupted
            if case TomlError.parseError = error {
                await restoreFromBackup()
            }
        }
        isLoading = false
    }

    private func restoreFromBackup() async {
        do {
            try TomlParser.restoreBackup()
            servers = try TomlParser.parseMcpServers()
            showingBackupRestoredAlert = true
            error = nil
        } catch {
            self.error = "Failed to restore from backup: \${error.localizedDescription}"
        }
    }

    func addServer(_ server: McpServer) async {
        var updatedServers = servers
        updatedServers.append(server)
        await saveServers(updatedServers)
    }

    func updateServer(_ server: McpServer) async {
        var updatedServers = servers
        if let index = updatedServers.firstIndex(where: { $0.id == server.id }) {
            updatedServers[index] = server
            await saveServers(updatedServers)
        }
    }

    func deleteServer(_ server: McpServer) async {
        let updatedServers = servers.filter { $0.id != server.id }
        await saveServers(updatedServers)
    }

    func toggleServerEnabled(_ server: McpServer) async {
        var updatedServers = servers
        if let index = updatedServers.firstIndex(where: { $0.id == server.id }) {
            updatedServers[index].isEnabled.toggle()
            await saveServers(updatedServers)
        }
    }

    private func saveServers(_ servers: [McpServer]) async {
        do {
            try TomlParser.writeMcpServers(servers)
            self.servers = servers
            error = nil
        } catch {
            self.error = "Failed to save MCP servers: \${error.localizedDescription}"
        }
    }

    func startWatching() {
        let path = TomlParser.configFile.deletingLastPathComponent().path
        fileWatcher = FileWatcher(path: path) { [weak self] in
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
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Services/McpServerStore.swift
git commit -m "feat: add MCP server store with CRUD operations"
```

---

### Task 4: Create MCP Servers List View

**Files:**
- Create: `VibeHelper/Views/McpServersListView.swift`

- [ ] **Step 1: Write the MCP Servers List View

```swift
import SwiftUI

struct McpServersListView: View {
    @StateObject private var store = McpServerStore()
    @State private var showingNewServer = false
    @State private var selectedServer: McpServer? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Toolbar
                HStack {
                    Text("MCP Servers")
                        .font(.title2.weight(.bold))

                    Spacer()

                    Button { showingNewServer = true } label: {
                        Label("New Server", systemImage: "plus")
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
                } else if store.servers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "server.rack")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No MCP Servers Configured")
                            .font(.headline)
                        Text("Add MCP servers to enable Context7 and other MCP-based services.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Button("Add First Server") { showingNewServer = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: 16)], spacing: 16) {
                        ForEach(store.servers) { server in
                            McpServerCard(server: server) {
                                selectedServer = server
                            } onToggle: {
                                Task { await store.toggleServerEnabled(server) }
                            }
                            .contextMenu {
                                Button {
                                    selectedServer = server
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }

                                Button {
                                    Task { await store.deleteServer(server) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }

                if let error = store.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color.vibeDanger)
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(Color.vibeDanger)
                        Spacer()
                        if error.contains("restore") {
                            Button("Restore Backup") {
                                Task { await store.load() }
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color.vibePrimary)
                        }
                    }
                    .padding(8)
                    .background(Color.vibeDanger.opacity(0.1))
                    .cornerRadius(8)
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
        .sheet(item: $selectedServer) { server in
            McpServerEditorView(server: server, store: store)
        }
        .sheet(isPresented: $showingNewServer) {
            McpServerEditorView(store: store)
        }
        .alert("Backup Restored", isPresented: $store.showingBackupRestoredAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("MCP servers were restored from backup.")
        }
    }
}

private struct McpServerCard: View {
    let server: McpServer
    let onEdit: () -> Void
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(server.name)
                    .font(.headline)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { server.isEnabled },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(server.url)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack {
                    Text(server.transport)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)

                    Text(server.apiKeyEnv)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                }
            }

            HStack {
                Button("Edit") { onEdit() }
                    .buttonStyle(.bordered)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Views/McpServersListView.swift
git commit -m "feat: add MCP servers list view"
```

---

### Task 5: Create MCP Server Editor View

**Files:**
- Create: `VibeHelper/Views/McpServerEditorView.swift`

- [ ] **Step 1: Write the MCP Server Editor View

```swift
import SwiftUI

struct McpServerEditorView: View {
    @ObservedObject var store: McpServerStore
    @State private var server: McpServer
    @State private var isNewServer: Bool
    @Environment(\.$0.dismiss) private var dismiss

    @State private var showingValidationError = false
    @State private var validationError = ""

    init(store: McpServerStore, server: McpServer? = nil) {
        self.store = store
        if let server = server {
            self._server = State(initialValue: server)
            self._isNewServer = State(initialValue: false)
        } else {
            self._server = State(initialValue: McpServer(
                name: "",
                transport: "streamable-http",
                url: "",
                headers: [:],
                apiKeyEnv: ""
            ))
            self._isNewServer = State(initialValue: true)
        }
    }

    private var isFormValid: Bool {
        !server.name.isEmpty &&
        !server.url.isEmpty &&
        !server.apiKeyEnv.isEmpty &&
        URL(string: server.url) != nil
    }

    private func validateAndSave() {
        guard isFormValid else {
            validationError = "Please fill in all required fields and use a valid URL."
            showingValidationError = true
            return
        }

        // Check for duplicate names (excluding current server)
        let hasDuplicateName = store.servers.contains {
            $0.name == server.name && $0.id != server.id
        }

        if hasDuplicateName {
            validationError = "A server with this name already exists."
            showingValidationError = true
            return
        }

        Task {
            if isNewServer {
                await store.addServer(server)
            } else {
                await store.updateServer(server)
            }
            dismiss()
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Server Details")) {
                    TextField("Name", text: $server.name)
                    TextField("URL", text: $server.url)
                        .textContentType(.URL)

                    Picker("Transport", selection: $server.transport) {
                        Text("Streamable HTTP").tag("streamable-http")
                        Text("HTTP").tag("http")
                        Text("WebSocket").tag("websocket")
                    }

                    TextField("API Key Environment Variable", text: $server.apiKeyEnv)
                }

                Section(header: Text("Headers")) {
                    ForEach(Array(server.headers.keys), id: \.self) { key in
                        HStack {
                            Text(key)
                            TextField("Value", text: Binding(
                                get: { server.headers[key] ?? "" },
                                set: { server.headers[key] = $0 }
                            ))
                        }
                    }

                    Button(action: {
                        server.headers["Authorization"] = "Bearer {api_key}"
                    }) {
                        Label("Add Authorization Header", systemImage: "plus")
                    }

                    Button(action: {
                        server.headers.removeAll()
                    }) {
                        Label("Clear All Headers", systemImage: "trash")
                    }
                    .foregroundStyle(.red)
                }

                Section {
                    Button(action: validateAndSave) {
                        HStack {
                            Spacer()
                            Text(isNewServer ? "Add Server" : "Save Changes")
                            Spacer()
                        }
                    }
                    .disabled(!isFormValid)

                    if !isNewServer {
                        Button(role: .destructive, action: {
                            Task { await store.deleteServer(server) }
                            dismiss()
                        }) {
                            HStack {
                                Spacer()
                                Text("Delete Server")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isNewServer ? "New MCP Server" : "Edit Server")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Validation Error", isPresented: $showingValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationError)
            }
        }
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Views/McpServerEditorView.swift
git commit -m "feat: add MCP server editor view"
```

---

### Task 6: Add FileWatcher Utility

**Files:**
- Create: `VibeHelper/Services/FileWatcher.swift`

- [ ] **Step 1: Write the FileWatcher utility

```swift
import Foundation

final class FileWatcher {
    private var source: DispatchSourceFileSystemObject?
    private let queue = DispatchQueue(label: "com.vibehelper.filewatcher")
    private let path: String
    private let callback: () -> Void

    init(path: String, callback: @escaping () -> Void) {
        self.path = path
        self.callback = callback
    }

    func start() {
        let fileDescriptor = open(path, O_EVTONLY)
        guard fileDescriptor != -1 else { return }

        source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: queue
        )

        source?.setEventHandler {
            self.callback()
        }

        source?.setCancelHandler {
            close(fileDescriptor)
        }

        source?.resume()
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/Services/FileWatcher.swift
git commit -m "feat: add file watcher utility"
```

---

### Task 7: Integrate MCP Servers into Main App

**Files:**
- Modify: `VibeHelper/VibeHelperApp.swift`

- [ ] **Step 1: Add MCP Servers tab to main navigation

```swift
TabView {
    DashboardView()
        .tabItem { Label("Dashboard", systemImage: "chart.bar") }
    SkillsListView()
        .tabItem { Label("Skills", systemImage: "sparkles") }
    ModelsSettingsView()
        .tabItem { Label("Models", systemImage: "cpu") }
    UsageLimitsSettingsView(store: SessionStore())
        .tabItem { Label("Usage", systemImage: "gauge.with.dots.needle.bottom") }
    McpServersListView()
        .tabItem { Label("MCP", systemImage: "server.rack") }
}
```

- [ ] **Step 2: Commit

```bash
git add VibeHelper/VibeHelperApp.swift
git commit -m "feat: add MCP servers tab to main navigation"
```

---

Generated by Mistral Vibe.
Co-Authored-By: Mistral Vibe <vibe@mistral.ai>