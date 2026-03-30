import SwiftUI

enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

extension Color {
    static let vibePrimary = Color(
        nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.45, green: 0.65, blue: 1.0, alpha: 1.0)
                : NSColor(red: 0.30, green: 0.50, blue: 0.95, alpha: 1.0)
        }
    )

    static let vibeAccent = Color(
        nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 1.0, green: 0.65, blue: 0.35, alpha: 1.0)
                : NSColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0)
        }
    )
    static let vibeSuccess = Color(
        nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 0.35, green: 0.85, blue: 0.55, alpha: 1.0)
                : NSColor(red: 0.2, green: 0.7, blue: 0.4, alpha: 1.0)
        }
    )
    static let vibeWarning = Color(
        nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 1.0, green: 0.8, blue: 0.35, alpha: 1.0)
                : NSColor(red: 0.9, green: 0.65, blue: 0.15, alpha: 1.0)
        }
    )
    static let vibeDanger = Color(
        nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(red: 1.0, green: 0.45, blue: 0.45, alpha: 1.0)
                : NSColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        }
    )

    static let cardBackground = Color(nsColor: .controlBackgroundColor)
    static let subtleText = Color(nsColor: .secondaryLabelColor)
}

struct CardStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(
                color: colorScheme == .dark
                    ? .black.opacity(0.2)
                    : .black.opacity(0.05),
                radius: colorScheme == .dark ? 3 : 2,
                y: 1
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
