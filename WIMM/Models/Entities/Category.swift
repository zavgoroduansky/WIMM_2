import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: CategoryKind
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(
        id: UUID = UUID(),
        name: String,
        kind: CategoryKind = .expense,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.kind = kind
        self.createdAt = createdAt
        self.transactions = []
    }
}
