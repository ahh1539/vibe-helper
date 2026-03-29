import SwiftUI

struct TimeRangePickerView: View {
    @Binding var timeRange: TimeRange
    @State private var customStart = Date()
    @State private var customEnd = Date()
    @State private var showingCustom = false

    private let presets: [(label: String, range: TimeRange)] = [
        ("Today", .today),
        ("7 Days", .week),
        ("30 Days", .month),
        ("All Time", .allTime),
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(presets, id: \.label) { preset in
                Button(preset.label) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        timeRange = preset.range
                        showingCustom = false
                    }
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected(preset.range) ? Color.vibePrimary.opacity(0.2) : Color.clear)
                .foregroundStyle(isSelected(preset.range) ? Color.vibePrimary : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Divider().frame(height: 20)

            Button {
                showingCustom.toggle()
            } label: {
                Image(systemName: "calendar")
                    .foregroundStyle(showingCustom ? Color.vibePrimary : Color.secondary)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingCustom) {
                VStack(spacing: 12) {
                    DatePicker("From", selection: $customStart, displayedComponents: .date)
                    DatePicker("To", selection: $customEnd, displayedComponents: .date)
                    Button("Apply") {
                        timeRange = .custom(customStart, customEnd)
                        showingCustom = false
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(width: 260)
            }
        }
    }

    private func isSelected(_ range: TimeRange) -> Bool {
        switch (timeRange, range) {
        case (.today, .today), (.week, .week), (.month, .month), (.allTime, .allTime):
            return true
        default:
            return false
        }
    }
}
