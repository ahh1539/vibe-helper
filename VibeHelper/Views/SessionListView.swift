import SwiftUI

struct SessionListView: View {
    let sessions: [Session]
    @Binding var selectedSession: Session?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Sessions")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if sessions.isEmpty {
                Text("No sessions found")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(sessions.prefix(20)) { session in
                    SessionRow(session: session)
                        .onTapGesture {
                            selectedSession = session
                        }
                }
            }
        }
        .cardStyle()
    }
}

struct SessionRow: View {
    let session: Session

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title ?? "Untitled Session")
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.tail)

                HStack(spacing: 8) {
                    Text(session.startTime.shortFormatted)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(session.formattedDuration)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(session.projectName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.vibePrimary.opacity(0.1))
                .foregroundStyle(Color.vibePrimary)
                .clipShape(Capsule())

            Text(session.stats.formattedCost)
                .font(.system(.body, design: .rounded, weight: .medium))
                .foregroundStyle(Color.vibeAccent)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.primary.opacity(0.02))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
    }
}
