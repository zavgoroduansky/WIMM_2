import Foundation

final class NewTransactionUseCase {
    enum TransactionMode: String, CaseIterable, Identifiable {
        case expense
        case income
        case transfer

        var id: String { rawValue }

        var title: String {
            switch self {
            case .expense: return "Expense"
            case .income: return "Income"
            case .transfer: return "Transfer"
            }
        }
    }

    struct Input {
        let mode: TransactionMode
        let amount: String
        let amountTo: String
        let selectedAccount: Account?
        let selectedCategory: Category?
        let fromAccount: Account?
        let toAccount: Account?
        let transactionCurrency: CurrencyCode
        let transferFromCurrency: CurrencyCode
        let transferToCurrency: CurrencyCode
        let date: Date
        let note: String
        let usesManualAmountTo: Bool
    }

    private let repository: FinanceRepositorying

    init(repository: FinanceRepositorying) {
        self.repository = repository
    }

    func loadData() -> (groups: [AccountGroup], categories: [Category]) {
        let groups = (try? repository.fetchAccountGroups()) ?? []
        let categories = (try? repository.fetchCategories()) ?? []
        return (groups, categories)
    }

    func save(input: Input) throws {
        let trimmedNote = input.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let note = trimmedNote.isEmpty ? nil : trimmedNote

        switch input.mode {
        case .income:
            guard let amountMinor = Money.minor(fromInput: input.amount),
                  amountMinor > 0,
                  let account = input.selectedAccount else {
                throw TransactionServiceError.invalidAmount
            }

            try repository.createIncome(
                amountMinor: amountMinor,
                account: account,
                currency: input.transactionCurrency,
                category: input.selectedCategory,
                date: input.date,
                note: note
            )
        case .expense:
            guard let amountMinor = Money.minor(fromInput: input.amount),
                  amountMinor > 0,
                  let account = input.selectedAccount else {
                throw TransactionServiceError.invalidAmount
            }

            try repository.createExpense(
                amountMinor: amountMinor,
                account: account,
                currency: input.transactionCurrency,
                category: input.selectedCategory,
                date: input.date,
                note: note
            )
        case .transfer:
            guard let amountMinor = Money.minor(fromInput: input.amount),
                  amountMinor > 0,
                  let fromAccount = input.fromAccount,
                  let toAccount = input.toAccount else {
                throw TransactionServiceError.invalidAmount
            }

            let toAmountMinor: Int64?
            if input.usesManualAmountTo {
                guard let parsed = Money.minor(fromInput: input.amountTo), parsed > 0 else {
                    throw TransactionServiceError.invalidAmount
                }
                toAmountMinor = parsed
            } else {
                toAmountMinor = nil
            }

            try repository.createTransfer(
                fromAccount: fromAccount,
                toAccount: toAccount,
                fromCurrency: input.transferFromCurrency,
                toCurrency: input.transferToCurrency,
                amountFromMinor: amountMinor,
                amountToMinor: toAmountMinor,
                date: input.date,
                note: note
            )
        }
    }
}
