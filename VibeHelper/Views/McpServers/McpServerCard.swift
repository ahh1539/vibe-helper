import SwiftUI

/// Reusable card component for displaying an MCP server
struct McpServerCard: View {
    let server: McpServer
    let onTap: () -> Void
    let onToggle: (Bool) -> Void
    let isToggleDisabled: Bool
    
    @State private var isPresented = false
    
    init(
        server: McpServer,
        onTap: @escaping () -> Void = {},
        onToggle: @escaping (Bool) -> Void = { _ in },
        isToggleDisabled: Bool = false
    ) {
        self.server = server
        self.onTap = onTap
        self.onToggle = onToggle
        self.isToggleDisabled = isToggleDisabled
    }
    
    var body: some View {
        Button(action: { 
            onTap()
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: server.isEnabled ? "server.rack" : "server.rack")
                    .font(.title2)
                    .foregroundColor(server.isEnabled ? .green : .gray)
                    .padding(.leading, 4)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(server.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(server.transport.uppercased())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                    
                    Group {
                        if !server.headers.isEmpty {
                            labelsView
                        } else if !server.apiKeyEnv.isEmpty {
                            Text("Auth: \(server.apiKeyEnv)")
                                .font(.subheadline)
                        } else if server.transport == "stdio" && !server.command.isEmpty {
                            Text("Command: \(server.command)")
                                .font(.subheadline)
                        } else if !server.url.isEmpty {
                            Text("URL: \(server.url)")
                                .font(.subheadline)
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                Toggle("", isOn: Binding(
                    get: { server.isEnabled },
                    set: { newValue in
                        onToggle(newValue)
                    }
                ))
                .disabled(isToggleDisabled)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var labelsView: some View {
        HStack(spacing: 8) {
            ForEach(Array(server.headers.prefix(2)), id: \.key) { key, _ in
                let title = "\(key)=***"
                TagView(title: title)
            }
            
            if server.headers.count > 2 {
                Text("+\\\((server.headers.count - 2)) more")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .font(.subheadline)
    }
}

/// Small tag-style label
private struct TagView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.secondary.opacity(0.15))
            .cornerRadius(6)
    }
}
