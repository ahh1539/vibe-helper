import SwiftUI

@MainActor
final class ReplayViewModel: ObservableObject {
    @Published var messages: [SessionMessage] = []
    @Published var isLoading = false

    func load(directoryURL: URL) async {
        isLoading = true
        messages = await MessageLoader.load(directoryURL: directoryURL)
        isLoading = false
    }
}

struct SessionReplayView: View {
    let session: Session
    var onPopToRoot: () -> Void
    var onPop: () -> Void

    @StateObject private var viewModel = ReplayViewModel()
    @State private var searchText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Breadcrumb
            SessionBreadcrumbBar(items: [
                BreadcrumbItem(label: "Dashboard", action: onPopToRoot),
                BreadcrumbItem(label: session.title ?? "Untitled Session", action: onPop),
                BreadcrumbItem(label: "Replay", action: {})
            ])
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("Search messages...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            Divider()

            // Messages
            if viewModel.isLoading {
                ProgressView("Loading conversation…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.messages.isEmpty {
                Text("No messages found")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredMessages.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No messages match \"\(searchText)\"")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(filteredMessages) { message in
                            MessageBubbleView(message: message)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .frame(minWidth: 640, minHeight: 600)
        .task {
            if let url = session.directoryURL {
                await viewModel.load(directoryURL: url)
            }
        }
    }

    private var filteredMessages: [SessionMessage] {
        guard !searchText.isEmpty else { return viewModel.messages }
        let query = searchText.lowercased()
        return viewModel.messages.filter { message in
            if let content = message.content, content.localizedCaseInsensitiveContains(query) {
                return true
            }
            if let name = message.name, name.localizedCaseInsensitiveContains(query) {
                return true
            }
            if let toolCalls = message.toolCalls {
                for tc in toolCalls {
                    if tc.function.name.localizedCaseInsensitiveContains(query) {
                        return true
                    }
                }
            }
            return false
        }
    }
}

struct MessageBubbleView: View {
    let message: SessionMessage

    var body: some View {
        switch message.role {
        case .user:
            UserMessageView(message: message)
        case .assistant:
            AssistantMessageView(message: message)
        case .tool:
            ToolResultCard(message: message)
                .padding(.leading, 24)
        }
    }
}

struct UserMessageView: View {
    let message: SessionMessage

    var body: some View {
        HStack {
            Spacer(minLength: 80)
            VStack(alignment: .trailing, spacing: 4) {
                Text("You")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let content = message.content, !content.isEmpty {
                    Text(content)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.vibePrimary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                }
            }
        }
    }
}

struct AssistantMessageView: View {
    let message: SessionMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Assistant")
                .font(.caption2)
                .foregroundStyle(Color.vibeAccent)

            if let content = message.content, !content.isEmpty {
                Text(content)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let toolCalls = message.toolCalls {
                ForEach(toolCalls) { tc in
                    ToolCallCard(toolCall: tc)
                }
            }
        }
    }
}

struct ToolCallCard: View {
    let toolCall: ToolCall
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: iconName(for: toolCall.function.name))
                    .font(.caption)
                    .foregroundStyle(Color.vibePrimary)
                Text(toolCall.function.name)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.vibePrimary)
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture { isExpanded.toggle() }

            if isExpanded {
                Divider()
                Text(prettyArguments(toolCall.function.arguments))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
        }
        .background(Color.vibePrimary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.vibePrimary.opacity(0.15), lineWidth: 1)
        )
    }

    private func prettyArguments(_ raw: String) -> String {
        guard let data = raw.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: pretty, encoding: .utf8) else {
            return raw
        }
        return str
    }

    private func iconName(for tool: String) -> String {
        switch tool {
        case "bash": return "terminal"
        case "read_file": return "doc.text"
        case "write_file": return "square.and.pencil"
        case "search_replace": return "magnifyingglass"
        case "grep": return "line.3.horizontal.decrease.circle"
        case "todo": return "checklist"
        default: return "wrench.and.screwdriver"
        }
    }
}

struct ToolResultCard: View {
    let message: SessionMessage
    @State private var isExpanded = false
    private let previewLimit = 400

    private var content: String { message.content ?? "" }
    private var isLong: Bool { content.count > previewLimit }
    private var displayContent: String {
        isExpanded ? content : String(content.prefix(previewLimit))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.turn.down.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(message.name ?? "result")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Text(displayContent + (isLong && !isExpanded ? "…" : ""))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isLong {
                Button(isExpanded ? "Show less" : "Show more") {
                    isExpanded.toggle()
                }
                .font(.caption)
                .buttonStyle(.plain)
                .foregroundStyle(Color.vibePrimary)
            }
        }
        .padding(10)
        .background(Color.primary.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}
