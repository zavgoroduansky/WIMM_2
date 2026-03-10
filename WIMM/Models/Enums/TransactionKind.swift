import Foundation

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case income
    case expense

    var id: String { rawValue }
}
