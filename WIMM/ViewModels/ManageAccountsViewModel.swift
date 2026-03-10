import Foundation
import Combine

@MainActor
final class ManageAccountsViewModel: ObservableObject {
    @Published private(set) var accountGroups: [AccountGroup] = []
    @Published private(set) var accountIDsWithTransactions: Set<UUID> = []

    func load(using repository: FinanceRepositorying) {
        accountGroups = (try? repository.fetchAccountGroups()) ?? []
        let transactions = (try? repository.fetchTransactions()) ?? []
        accountIDsWithTransactions = Set(transactions.map(\.account.id))
    }

    var orderedGroups: [AccountGroup] {
        orderedGroups(from: accountGroups)
    }

    func orderedGroups(from accountGroups: [AccountGroup]) -> [AccountGroup] {
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

    func deleteGroup(_ group: AccountGroup, using repository: FinanceRepositorying) {
        repository.delete(group)
        try? repository.save()
    }

    func canDeleteAccount(_ account: Account) -> Bool {
        !accountIDsWithTransactions.contains(account.id)
    }

    func deleteAccountBlockedReason(_ account: Account) -> String? {
        if canDeleteAccount(account) {
            return nil
        }
        return "Cannot delete this account because it already has transactions."
    }

    func canEditAccountStructure(_ account: Account) -> Bool {
        !accountIDsWithTransactions.contains(account.id)
    }

    func deleteAccount(_ account: Account, using repository: FinanceRepositorying) {
        guard canDeleteAccount(account) else { return }
        repository.delete(account)
        try? repository.save()
    }

    func renameGroup(_ group: AccountGroup, to newName: String, using repository: FinanceRepositorying) {
        group.name = newName
        try? repository.save()
    }

    func updateAccount(
        _ account: Account,
        name: String,
        iconName: String?,
        primaryCurrency: CurrencyCode,
        enabledCurrencies: [CurrencyCode],
        accountGroup: AccountGroup,
        using repository: FinanceRepositorying
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        account.name = trimmedName
        account.iconName = iconName

        if canEditAccountStructure(account) {
            account.primaryCurrency = primaryCurrency
            account.enabledCurrencies = enabledCurrencies
            if account.accountGroup.id != accountGroup.id {
                account.accountGroup = accountGroup
                let maxOrderInGroup = accountGroup.accounts.map(\.sortOrder).max() ?? -1
                account.sortOrder = maxOrderInGroup + 1
            }
        }

        try? repository.save()
    }

    func moveGroups(from source: IndexSet, to destination: Int, current: [AccountGroup], using repository: FinanceRepositorying) {
        var mutable = orderedGroups(from: current)
        moveElements(in: &mutable, from: source, to: destination)

        for (index, group) in mutable.enumerated() {
            group.sortOrder = index
        }

        try? repository.save()
    }

    func moveAccounts(in group: AccountGroup, source: IndexSet, destination: Int, using repository: FinanceRepositorying) {
        var mutable = accounts(in: group)
        moveElements(in: &mutable, from: source, to: destination)

        for (index, account) in mutable.enumerated() {
            account.sortOrder = index
        }

        try? repository.save()
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
    @Published private(set) var categories: [Category] = []
    @Published private(set) var categoryIDsWithTransactions: Set<UUID> = []

    func load(using repository: FinanceRepositorying) {
        categories = (try? repository.fetchCategories()) ?? []
        let transactions = (try? repository.fetchTransactions()) ?? []
        categoryIDsWithTransactions = Set(transactions.compactMap { $0.category?.id })
    }

    var expenseCategories: [Category] {
        sortedCategories(from: categories, kind: .expense)
    }

    var incomeCategories: [Category] {
        sortedCategories(from: categories, kind: .income)
    }

    func sortedCategories(from categories: [Category], kind: CategoryKind) -> [Category] {
        categories
            .filter { $0.kind == kind }
            .sorted { lhs, rhs in
                lhs.name < rhs.name
            }
    }

    func canDeleteCategory(_ category: Category) -> Bool {
        !categoryIDsWithTransactions.contains(category.id)
    }

    func deleteCategoryBlockedReason(_ category: Category) -> String? {
        if canDeleteCategory(category) {
            return nil
        }
        return "Cannot delete this category because it already has transactions."
    }

    func canEditCategoryKind(_ category: Category) -> Bool {
        !categoryIDsWithTransactions.contains(category.id)
    }

    func deleteCategory(_ category: Category, using repository: FinanceRepositorying) {
        guard canDeleteCategory(category) else { return }
        repository.delete(category)
        try? repository.save()
    }

    func updateCategory(
        _ category: Category,
        name: String,
        kind: CategoryKind,
        colorHex: String,
        using repository: FinanceRepositorying
    ) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        category.name = trimmedName
        category.colorHex = colorHex

        if canEditCategoryKind(category) {
            category.kind = kind
        }
        try? repository.save()
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

    func save(account: Account, using repository: FinanceRepositorying) {
        let finalSelected = selected.isEmpty ? [primary] : Array(selected)
        account.primaryCurrency = primary
        account.enabledCurrencies = finalSelected
        try? repository.save()
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

@MainActor
final class EditAccountViewModel: ObservableObject {
    @Published var name: String
    @Published var iconName: String
    @Published var selectedGroupID: UUID
    @Published var selectedCurrencies: Set<CurrencyCode>
    @Published var primaryCurrency: CurrencyCode

    let canEditStructure: Bool
    let iconOptions = ["wallet.pass", "banknote", "creditcard", "house", "car", "briefcase", "cart", "star"]

    init(account: Account, canEditStructure: Bool) {
        self.name = account.name
        self.iconName = account.iconName ?? "wallet.pass"
        self.selectedGroupID = account.accountGroup.id
        self.selectedCurrencies = Set(account.enabledCurrencies)
        self.primaryCurrency = account.primaryCurrency
        self.canEditStructure = canEditStructure
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedCurrencies.isEmpty
    }

    func toggleCurrency(_ currency: CurrencyCode, isOn: Bool) {
        if isOn {
            selectedCurrencies.insert(currency)
        } else {
            selectedCurrencies.remove(currency)
        }

        if selectedCurrencies.isEmpty {
            selectedCurrencies.insert(primaryCurrency)
            return
        }

        if !selectedCurrencies.contains(primaryCurrency), let first = selectedCurrencies.first {
            primaryCurrency = first
        }
    }
}

@MainActor
final class EditCategoryViewModel: ObservableObject {
    @Published var name: String
    @Published var kind: CategoryKind
    @Published var colorHex: String

    let canEditKind: Bool

    init(category: Category, canEditKind: Bool) {
        self.name = category.name
        self.kind = category.kind
        self.colorHex = category.colorHex ?? CategoryColorPalette.defaultHex
        self.canEditKind = canEditKind
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
