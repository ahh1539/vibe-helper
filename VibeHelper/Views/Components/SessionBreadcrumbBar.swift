import SwiftUI

struct BreadcrumbItem {
    let label: String
    let action: () -> Void
}

struct SessionBreadcrumbBar: View {
    let items: [BreadcrumbItem]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                if index > 0 {
                    Image(systemName: "chevron.forward")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                if index == items.count - 1 {
                    Text(item.label)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(.primary)
                } else {
                    Button(action: item.action) {
                        Text(item.label)
                            .font(.callout.weight(.medium))
                            .foregroundStyle(Color.vibePrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
}
