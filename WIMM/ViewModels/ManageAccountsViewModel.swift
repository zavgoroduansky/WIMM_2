import Foundation
import Combine
import SwiftData

@MainActor
final class ManageAccountsViewModel: ObservableObject {
    private(set) var accountGroups: [AccountGroup] = []

    func update(accountGroups: [AccountGroup]) {
        self.accountGroups = accountGroups
    }

    var orderedGroups: [AccountGroup] {
        accountGroups.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    func accounts(in group: AccountGroup) -> [Account] {
        group.accounts.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    func deleteGroup(_ group: AccountGroup, in modelContext: ModelContext) {
        modelContext.delete(group)
        try? modelContext.save()
    }

    func deleteAccount(_ account: Account, in modelContext: ModelContext) {
        modelContext.delete(account)
        try? modelContext.save()
    }

    func renameGroup(_ group: AccountGroup, to newName: String, in modelContext: ModelContext) {
        group.name = newName
        try? modelContext.save()
    }

    func renameAccount(_ account: Account, to newName: String, in modelContext: ModelContext) {
        account.name = newName
        try? modelContext.save()
    }

    func moveGroups(from source: IndexSet, to destination: Int, in modelContext: ModelContext) {
        var mutable = orderedGroups
        moveElements(in: &mutable, from: source, to: destination)

        for (index, group) in mutable.enumerated() {
            group.sortOrder = index
        }

        try? modelContext.save()
    }

    func moveAccounts(in group: AccountGroup, source: IndexSet, destination: Int, in modelContext: ModelContext) {
        var mutable = accounts(in: group)
        moveElements(in: &mutable, from: source, to: destination)

        for (index, account) in mutable.enumerated() {
            account.sortOrder = index
        }

        try? modelContext.save()
    }

    private func moveElements<T>(in array: inout [T], from source: IndexSet, to destination: Int) {
        let items = source.sorted().map { array[$0] }
        for index in source.sorted(by: >) {
            array.remove(at: index)
        }

        var insertIndex = destination
        for index in source {
            if index < destination {
                insertIndex -= 1
            }
        }

        array.insert(contentsOf: items, at: max(0, min(insertIndex, array.count)))
    }
}

@MainActor
final class ManageCategoriesViewModel: ObservableObject {
    private(set) var categories: [Category] = []

    func update(categories: [Category]) {
        self.categories = categories
    }

    var sortedCategories: [Category] {
        categories.sorted { lhs, rhs in
            if lhs.kind == rhs.kind {
                return lhs.name < rhs.name
            }
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
    }

    func deleteCategory(_ category: Category, in modelContext: ModelContext) {
        modelContext.delete(category)
        try? modelContext.save()
    }

    func renameCategory(_ category: Category, to newName: String, in modelContext: ModelContext) {
        category.name = newName
        try? modelContext.save()
    }
}

@MainActor
final class EditAccountCurrenciesViewModel: ObservableObject {
    @Published var selected: Set<CurrencyCode> = []
    @Published var primary: CurrencyCode = .eur

    func applyInitialState(from account: Account) {
        selected = Set(account.enabledCurrencies)
        if selected.isEmpty {
            selected.insert(account.primaryCurrency)
        }
        primary = account.primaryCurrency
        if !selected.contains(primary) {
            selected.insert(primary)
        }
    }

    func toggleCurrency(_ currency: CurrencyCode, isOn: Bool) {
        if isOn {
            selected.insert(currency)
        } else {
            selected.remove(currency)
        }

        if !selected.contains(primary), let first = selected.first {
            primary = first
        }
    }

    func save(account: Account, in modelContext: ModelContext) {
        let finalSelected = selected.isEmpty ? [primary] : Array(selected)
        account.primaryCurrency = primary
        account.enabledCurrencies = finalSelected
        try? modelContext.save()
    }
}

@MainActor
final class RenameEntityViewModel: ObservableObject {
    @Published var name: String

    init(initialName: String) {
        self.name = initialName
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canSave: Bool {
        !trimmedName.isEmpty
    }
}
