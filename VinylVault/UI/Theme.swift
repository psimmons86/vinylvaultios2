import SwiftUI

// MARK: - Color Scheme
struct AppColors {
    // Primary colors
    static let primary = Color(hex: "00C9A7")      // Teal (now primary)
    static let secondary = Color(hex: "FF00FF")    // Magenta
    static let tertiary = Color(hex: "6C63FF")     // Vibrant purple
    
    // Accent colors
    static let accent1 = Color(hex: "FFC75F")      // Warm yellow
    static let accent2 = Color(hex: "845EC2")      // Deep purple
    static let accent3 = Color(hex: "FF9671")      // Soft orange
    
    // Background colors
    static let background = Color(hex: "F8F9FA")   // Light gray
    static let cardBackground = Color(hex: "00C9A7") // Teal for cards
    
    // Text colors
    static let textPrimary = Color(hex: "FF00FF")  // Magenta
    static let textSecondary = Color(hex: "845EC2") // Deep purple
    static let textLight = Color.white             // White for text on teal
}

// MARK: - Typography
struct AppFonts {
    static let titleLarge = Font.system(size: 28, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 22, weight: .bold, design: .rounded)
    static let titleSmall = Font.system(size: 18, weight: .semibold, design: .rounded)
    
    static let bodyLarge = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 14, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 12, weight: .regular, design: .rounded)
    
    static let caption = Font.system(size: 10, weight: .medium, design: .rounded)
}

// MARK: - Shapes & Styles
struct AppShapes {
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 16
    static let cornerRadiusExtraLarge: CGFloat = 24
}

// MARK: - Animations
struct AppAnimations {
    static let standard = Animation.spring(response: 0.3, dampingFraction: 0.7)
    static let slow = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let fast = Animation.spring(response: 0.2, dampingFraction: 0.7)
}

// MARK: - Helper Extensions
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
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
