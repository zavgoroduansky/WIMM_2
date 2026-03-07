import Foundation

enum CurrencyCode: String, Codable, CaseIterable, Identifiable {
    case eur
    case usd
    case uah

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .eur: return "€"
        case .usd: return "$"
        case .uah: return "₴"
        }
    }

    var displayName: String {
        switch self {
        case .eur: return "Euro"
        case .usd: return "US Dollar"
        case .uah: return "Ukrainian Hryvnia"
        }
    }

    var localeIdentifier: String {
        switch self {
        case .eur: return "en_IE"
        case .usd: return "en_US"
        case .uah: return "uk_UA"
        }
    }
}
