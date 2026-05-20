import SwiftUI

extension Color {
    struct AppTheme {
        static let primary = Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark 
                ? UIColor(red: 75/255, green: 147/255, blue: 255/255, alpha: 1) // Lighter Blue for Dark Mode
                : UIColor(red: 30/255, green: 58/255, blue: 138/255, alpha: 1) // Deep Blue for Light Mode
        })
        
        // Semantic UI colors that automatically switch between Light/Dark mode
        static let secondary = Color(UIColor.secondarySystemGroupedBackground) // Card backgrounds
        static let background = Color(UIColor.systemGroupedBackground) // Main View backgrounds
        
        static let textPrimary = Color.primary
        static let textSecondary = Color.secondary
        
        static let success = Color(hex: "4CAF50") // Soft Green
        static let error = Color(hex: "F44336") // Soft Red
    }
<<<<<<< Updated upstream
=======
<<<<<<< HEAD
    
    public init(hex: String) {
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
=======
>>>>>>> d446cd839f940e918615e25b1611255a844f72f6
>>>>>>> Stashed changes
}

extension Font {
    struct AppTheme {
        static let title = Font.system(size: 32, weight: .bold, design: .default)
        static let subtitle = Font.system(size: 16, weight: .medium, design: .default)
        static let body = Font.system(size: 14, weight: .regular, design: .default)
        static let button = Font.system(size: 16, weight: .semibold, design: .default)
        static let caption = Font.system(size: 12, weight: .regular, design: .default)
        static let input = Font.system(size: 16, weight: .regular, design: .default)
    }
}

extension View {
    @ViewBuilder
    func disableAutocapitalization() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func hideNavigationBar() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS)
        self.navigationBarHidden(true)
        #else
        self
        #endif
    }
}
