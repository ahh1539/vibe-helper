import SwiftUI

enum McpServerEditorMode {
    case create
    case edit(McpServer)
}

/// View for creating and editing MCP server configurations
struct McpServerEditorView: View {
    let mode: McpServerEditorMode
    @ObservedObject var store: McpServerStore
    @Environment(\.dismiss) private var dismiss

    @State private var server: McpServer
    @State private var showAdvanced = false
    @State private var timeoutText = "30"
    @State private var startupTimeoutText = "15"
    @State private var toolTimeoutText = "120"
    @State private var errorMessage: String? = nil

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    init(store: McpServerStore, mode: McpServerEditorMode) {
        self.store = store
        self.mode = mode

        switch mode {
        case .create:
            _server = State(initialValue: McpServer(name: "", transport: "stdio"))
            _timeoutText = State(initialValue: "30")
            _startupTimeoutText = State(initialValue: "15")
            _toolTimeoutText = State(initialValue: "120")
        case .edit(let existingServer):
            _server = State(initialValue: existingServer)
            _timeoutText = State(initialValue: String(existingServer.timeout))
            _startupTimeoutText = State(initialValue: String(existingServer.startupTimeoutSec))
            _toolTimeoutText = State(initialValue: String(existingServer.toolTimeoutSec))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit MCP Server" : "New MCP Server")
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
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Server Name")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("my-mcp-server", text: $server.name)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Transport
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transport Protocol")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Transport", selection: $server.transport) {
                            Text("stdio").tag("stdio")
                            Text("HTTP").tag("http")
                            Text("SSE").tag("sse")
                            Text("Streamable HTTP").tag("streamablehttp")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }

                    // URL/Command based on transport
                    if server.transport == "stdio" {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Command")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Command to execute", text: $server.command)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Arguments (optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Space-separated arguments", text: Binding(
                                get: { server.args.joined(separator: " ") },
                                set: { server.args = $0.components(separatedBy: .whitespaces).filter { !$0.isEmpty } }
                            ))
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Server URL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("http://localhost:8000", text: $server.url)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }
                    }

                    Divider()

                    // Authentication
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Authentication")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Key Environment Variable")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("MY_API_KEY", text: $server.apiKeyEnv)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Key Header")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Authorization", text: $server.apiKeyHeader)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("API Key Format")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("Bearer {token}", text: $server.apiKeyFormat)
                                .textFieldStyle(.roundedBorder)
                                .disableAutocorrection(true)
                        }
                    }

                    // Headers
                    if !server.headers.isEmpty || (server.apiKeyEnv.isEmpty && server.apiKeyHeader.isEmpty) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("HTTP Headers (optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(0..<max(1, server.headers.count + 1), id: \.self) { index in
                                HStack {
                                    TextField("Header Name", text: Binding(
                                        get: { index < server.headers.count ? Array(server.headers.keys)[index] : "" },
                                        set: { newKey in
                                            if index < server.headers.count {
                                                let oldKey = Array(server.headers.keys)[index]
                                                let value = server.headers[oldKey] ?? ""
                                                if !newKey.isEmpty {
                                                    server.headers[newKey] = value
                                                    server.headers.removeValue(forKey: oldKey)
                                                }
                                            } else if !newKey.isEmpty {
                                                server.headers[newKey] = ""
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 120)

                                    Text(":")

                                    TextField("Value", text: Binding(
                                        get: { index < server.headers.count ? Array(server.headers.values)[index] : "" },
                                        set: { newValue in
                                            if index < server.headers.count {
                                                let key = Array(server.headers.keys)[index]
                                                if newValue.isEmpty {
                                                    server.headers.removeValue(forKey: key)
                                                } else {
                                                    server.headers[key] = newValue
                                                }
                                            } else if !newValue.isEmpty {
                                                let key = "Header \(index + 1)"
                                                server.headers[key] = newValue
                                            }
                                        }
                                    ))
                                    .textFieldStyle(.roundedBorder)

                                    if index < server.headers.count {
                                        Button(role: .destructive) {
                                            let keyToRemove = Array(server.headers.keys)[index]
                                            server.headers.removeValue(forKey: keyToRemove)
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // Environment Variables
                    if !server.env.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Environment Variables (optional)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            ForEach(Array(server.env.keys), id: \.self) { key in
                                HStack {
                                    Text(key)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("", text: Binding(
                                        get: { server.env[key] ?? "" },
                                        set: { server.env[key] = $0 }
                                    ))
                                    .textFieldStyle(.roundedBorder)

                                    Button(role: .destructive) {
                                        server.env.removeValue(forKey: key)
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            Button { server.env["NEW_ENV_VAR"] = "" } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(Color.vibePrimary)
                                Text("Add Environment Variable")
                                    .font(.caption)
                                    .foregroundStyle(Color.vibePrimary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Advanced Section (Timeouts)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Advanced")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                withAnimation { showAdvanced.toggle() }
                            } label: {
                                Image(systemName: showAdvanced ? "chevron.up" : "chevron.down")
                            }
                            .buttonStyle(.plain)
                        }

                        if showAdvanced {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Legacy Timeout (sec)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("30", text: $timeoutText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Startup Timeout (sec)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("15", text: $startupTimeoutText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Tool Timeout (sec)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    TextField("120", text: $toolTimeoutText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 80)
                                }
                            }
                        }
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
                Button(isEditing ? "Save" : "Create") { saveServer() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(server.name.isEmpty)
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private func saveServer() {
        // Validate
        guard !server.name.isEmpty else {
            errorMessage = "Server name is required"
            return
        }

        if server.transport != "stdio" && server.url.isEmpty {
            errorMessage = "URL is required for HTTP transports"
            return
        }

        if server.transport == "stdio" && server.command.isEmpty {
            errorMessage = "Command is required for stdio transport"
            return
        }

        // Apply timeouts
        if let timeoutValue = Int(timeoutText), timeoutValue > 0 {
            server.timeout = timeoutValue
        } else {
            server.timeout = 30
        }

        if let startupTimeoutValue = Int(startupTimeoutText), startupTimeoutValue > 0 {
            server.startupTimeoutSec = startupTimeoutValue
        } else {
            errorMessage = "Startup timeout must be positive"
            return
        }

        if let toolTimeoutValue = Int(toolTimeoutText), toolTimeoutValue > 0 {
            server.toolTimeoutSec = toolTimeoutValue
        } else {
            errorMessage = "Tool timeout must be positive"
            return
        }

        if (!server.apiKeyEnv.isEmpty || !server.apiKeyHeader.isEmpty) && server.apiKeyFormat.isEmpty {
            errorMessage = "API key format is required when using API key authentication"
            return
        }

        // Save
        Task {
            if isEditing {
                await store.updateServer(server)
            } else {
                await store.addServer(server)
            }
            dismiss()
        }
    }
}
