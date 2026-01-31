import SwiftUI

struct AppTheme {
    
    // MARK: - Colors
    
    // Background Colors
    static let background = Color(hex: "121826")
    static let surface = Color(hex: "1F2937")
    static let card = Color(hex: "2C3E50")
    static let cardHighlight = Color(hex: "374151")
    
    // Accent Colors
    static let primaryAccent = Color(hex: "00D9FF")
    static let secondaryAccent = Color(hex: "FFA726")
    static let success = Color(hex: "4ADE80")
    static let warning = Color(hex: "FFA726")
    static let danger = Color(hex: "FF5252")
    
    // Text Colors
    static let textPrimary = Color(hex: "F8FAFC")
    static let textSecondary = Color(hex: "94A3B8")
    static let textDisabled = Color(hex: "64748B")
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "00D9FF"), Color(hex: "0EA5E9")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        colors: [Color(hex: "FFA726"), Color(hex: "FF6B35")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let darkGradient = LinearGradient(
        colors: [Color(hex: "1E2A3A"), Color(hex: "2C3E50")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let successGradient = LinearGradient(
        colors: [Color(hex: "4ADE80"), Color(hex: "22C55E")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Season Colors (updated for dark theme)
    static let springColor = Color(hex: "4ADE80")
    static let summerColor = Color(hex: "FFA726")
    static let autumnColor = Color(hex: "FF6B35")
    static let winterColor = Color(hex: "00D9FF")
    
    // MARK: - Shadows & Glows
    
    static func neonGlow(color: Color, radius: CGFloat = 10) -> some View {
        EmptyView()
            .shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius * 2, x: 0, y: 0)
    }
    
    static func cardShadow() -> some View {
        EmptyView()
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            .shadow(color: AppTheme.primaryAccent.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Color Extension (hex support)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
