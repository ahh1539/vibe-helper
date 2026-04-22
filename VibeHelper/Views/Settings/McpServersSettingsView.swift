import SwiftUI

/// Navigation entry point for MCP Servers configuration within Settings
struct McpServersSettingsView: View {
    var body: some View {
        VibeHelperListSection(
            icon: Image(systemName: "server.rack"),
            title: "MCP Servers"
        ) {
            NavigationLink(destination: McpServersListView()) {
                HStack {
                    Text("Configure MCP Servers")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// Helper for consistent Settings UI styling
struct VibeHelperListSection<Content: View>: View {
    let icon: Image
    let title: String
    let content: () -> Content
    
    init(icon: Image, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content
    }
    
    var body: some View {
        Section {
            content()
        } header: {
            Label {
                Text(title)
                    .font(.headline)
            } icon: {
                icon
            }
        }
    }
}
