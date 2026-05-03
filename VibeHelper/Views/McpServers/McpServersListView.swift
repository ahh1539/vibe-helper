import SwiftUI

/// Main view for listing, adding, editing MCP servers
struct McpServersListView: View {
    @StateObject private var store = McpServerStore()
    @State private var showingDeleteAlert = false
    @State private var serverToDelete: McpServer? = nil
    @State private var isShowingEditor = false
    @State private var editingServer: McpServer? = nil
    
    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.servers.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        enabledSection
                        
                        if store.servers.contains(where: { !$0.isEnabled }) {
                            disabledSection
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("MCP Servers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { 
                        editingServer = nil
                        isShowingEditor = true
                    }) {
                        Label("Add Server", systemImage: "plus")
                    }
                    .disabled(store.isLoading)
                }
            }
            .sheet(isPresented: $isShowingEditor) {
                if let editingServer {
                    McpServerEditorView(store: store, mode: .edit(editingServer))
                        .onDisappear { 
                            self.editingServer = nil
                            self.isShowingEditor = false
                        }
                } else {
                    McpServerEditorView(store: store, mode: .create)
                        .onDisappear { 
                            self.editingServer = nil
                            self.isShowingEditor = false
                        }
                }
            }
            .alert("Delete Server", isPresented: $showingDeleteAlert) {
                if let server = serverToDelete {
                    Button("Delete", role: .destructive) {
                        Task { await store.deleteServer(server) }
                    }
                    Button("Cancel", role: .cancel) {
                        serverToDelete = nil
                    }
                }
            } message: {
                Text("Are you sure you want to delete this MCP server?")
            }
            .alert("Error", isPresented: .constant(store.lastError != nil)) {
                Button("OK", role: .cancel) {
                    store.lastError = nil
                }
            } message: {
                Text(store.lastError ?? "Unknown error")
            }
            .refreshable {
                await store.refreshFromDisk()
            }
        }
        .task {
            await store.load()
        }
    }
    
    private var enabledSection: some View {
        Section {
            ForEach(store.servers.filter { $0.isEnabled }) { server in
                McpServerCard(
                    server: server,
                    onTap: { 
                        editingServer = server
                        isShowingEditor = true
                    },
                    onToggle: { enabled in
                        Task {
                            await store.toggleServer(server, enabled: enabled)
                        }
                    },
                    isToggleDisabled: store.isLoading
                )
            }
        } header: {
            Text("Enabled")
        } footer: {
            if store.servers.filter({ $0.isEnabled }).isEmpty {
                Text("No enabled servers. Add one above.")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var disabledSection: some View {
        Section {
            ForEach(store.servers.filter { !$0.isEnabled }) { server in
                McpServerCard(
                    server: server,
                    onTap: { 
                        editingServer = server
                        isShowingEditor = true
                    },
                    onToggle: { enabled in
                        Task {
                            await store.toggleServer(server, enabled: enabled)
                        }
                    },
                    isToggleDisabled: store.isLoading
                )
            }
        } header: {
            Text("Disabled")
        }
    }
}

// Empty state view
private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "server.rack")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
                .padding(.bottom, 8)
            
            Text("No MCP Servers Configured")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Add MCP servers to enable Context7 and other MCP-based services.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
