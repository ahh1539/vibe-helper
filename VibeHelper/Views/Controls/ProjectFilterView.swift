import SwiftUI

struct ProjectFilterView: View {
    let projects: [String]
    @Binding var selectedProject: String?

    var body: some View {
        Menu {
            Button {
                selectedProject = nil
            } label: {
                HStack {
                    Text("All Projects")
                    if selectedProject == nil {
                        Image(systemName: "checkmark")
                    }
                }
            }
            Divider()
            ForEach(projects, id: \.self) { project in
                Button {
                    selectedProject = project
                } label: {
                    HStack {
                        Text(project)
                        if selectedProject == project {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "folder")
                Text(selectedProject ?? "All Projects")
                    .lineLimit(1)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.vibePrimary.opacity(selectedProject != nil ? 0.2 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}
