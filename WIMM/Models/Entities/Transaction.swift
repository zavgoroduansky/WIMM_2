import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var kind: TransactionKind
    var amountMinor: Int64
    var currency: CurrencyCode
    var date: Date
    var note: String?
    var transferGroupId: UUID?
    var createdAt: Date

    var account: Account
    var category: Category?

    init(
        id: UUID = UUID(),
        kind: TransactionKind,
        amountMinor: Int64,
        currency: CurrencyCode,
        date: Date = .now,
        note: String? = nil,
        transferGroupId: UUID? = nil,
        createdAt: Date = .now,
        account: Account,
        category: Category? = nil
    ) {
        self.id = id
        self.kind = kind
        self.amountMinor = amountMinor
        self.currency = currency
        self.date = date
        self.note = note
        self.transferGroupId = transferGroupId
        self.createdAt = createdAt
        self.account = account
        self.category = category
    }
}
