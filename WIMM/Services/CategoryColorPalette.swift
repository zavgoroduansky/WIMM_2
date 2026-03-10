import SwiftUI

struct CategoryPaletteColor: Identifiable, Hashable {
    let id: String
    let hex: String
    let preview: Color

    init(hex: String) {
        self.id = hex
        self.hex = hex
        self.preview = Color(hex: hex) ?? .gray
    }
}

enum CategoryColorPalette {
    static let defaultHex = "#16A34A"

    static let colors: [CategoryPaletteColor] = [
        CategoryPaletteColor(hex: "#EF4444"),
        CategoryPaletteColor(hex: "#F97316"),
        CategoryPaletteColor(hex: "#F59E0B"),
        CategoryPaletteColor(hex: "#EAB308"),
        CategoryPaletteColor(hex: "#84CC16"),
        CategoryPaletteColor(hex: "#22C55E"),
        CategoryPaletteColor(hex: "#10B981"),
        CategoryPaletteColor(hex: "#14B8A6"),
        CategoryPaletteColor(hex: "#06B6D4"),
        CategoryPaletteColor(hex: "#0EA5E9"),
        CategoryPaletteColor(hex: "#3B82F6"),
        CategoryPaletteColor(hex: "#6366F1"),
        CategoryPaletteColor(hex: "#8B5CF6"),
        CategoryPaletteColor(hex: "#A855F7"),
        CategoryPaletteColor(hex: "#D946EF"),
        CategoryPaletteColor(hex: "#EC4899"),
        CategoryPaletteColor(hex: "#F43F5E"),
        CategoryPaletteColor(hex: "#A3A3A3"),
        CategoryPaletteColor(hex: "#737373"),
        CategoryPaletteColor(hex: "#525252")
    ]

    static func color(hex: String?) -> Color {
        Color(hex: hex ?? "") ?? .green
    }
}

extension Color {
    init?(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard cleaned.count == 6, let int = UInt64(cleaned, radix: 16) else {
            return nil
        }

        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self = Color(red: r, green: g, blue: b)
    }
}
