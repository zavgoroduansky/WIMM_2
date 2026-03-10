import Foundation
import Combine

@MainActor
final class AddAccountViewModel: ObservableObject {
    enum GroupMode: String, CaseIterable, Identifiable {
        case existing
        case new

        var id: String { rawValue }
    }

    @Published var name = ""
    @Published var primaryCurrency: CurrencyCode = .eur
    @Published var selectedCurrencies: Set<CurrencyCode> = [.eur]
    @Published var iconName = "wallet.pass"
    @Published var groupMode: GroupMode = .existing
    @Published var selectedAccountGroupID: UUID?
    @Published var newGroupName = ""

    let iconOptions = ["wallet.pass", "banknote", "creditcard", "house", "car", "briefcase", "cart", "star"]

    private(set) var accountGroups: [AccountGroup] = []
    private var didInitialize = false

    func update(accountGroups: [AccountGroup], defaultCurrencyRaw: String) {
        self.accountGroups = accountGroups

        if selectedAccountGroupID == nil {
            selectedAccountGroupID = orderedGroups.first?.id
        }

        if accountGroups.isEmpty {
            groupMode = .new
        }

        if !didInitialize {
            let defaultCurrency = CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
            selectedCurrencies = [defaultCurrency]
            primaryCurrency = defaultCurrency
            didInitialize = true
        }
    }

    func load(using repository: FinanceRepositorying, defaultCurrencyRaw: String) {
        let groups = (try? repository.fetchAccountGroups()) ?? []
        update(accountGroups: groups, defaultCurrencyRaw: defaultCurrencyRaw)
    }

    var orderedGroups: [AccountGroup] {
        accountGroups.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    var selectedAccountGroup: AccountGroup? {
        accountGroups.first { $0.id == selectedAccountGroupID }
    }

    var canSave: Bool {
        let validGroup: Bool
        if groupMode == .new {
            validGroup = !newGroupName.trimmed.isEmpty
        } else {
            validGroup = selectedAccountGroup != nil
        }

        return !name.trimmed.isEmpty && validGroup && !selectedCurrencies.isEmpty
    }

    func toggleCurrency(_ currency: CurrencyCode, isOn: Bool) {
        if isOn {
            selectedCurrencies.insert(currency)
        } else {
            selectedCurrencies.remove(currency)
        }

        if !selectedCurrencies.contains(primaryCurrency), let first = selectedCurrencies.first {
            primaryCurrency = first
        }
    }

    @discardableResult
    func save(using repository: FinanceRepositorying) -> Bool {
        guard canSave else { return false }

        let accountGroup: AccountGroup
        if groupMode == .new {
            let trimmedGroupName = newGroupName.trimmed
            guard !trimmedGroupName.isEmpty else { return false }
            let maxGroupOrder = accountGroups.map(\.sortOrder).max() ?? -1
            let createdGroup = repository.createAccountGroup(name: trimmedGroupName, sortOrder: maxGroupOrder + 1)
            accountGroup = createdGroup
        } else {
            guard let selected = selectedAccountGroup else { return false }
            accountGroup = selected
        }

        let maxOrderInGroup = accountGroup.accounts.map(\.sortOrder).max() ?? -1
        _ = repository.createAccount(
            name: name.trimmed,
            primaryCurrency: primaryCurrency,
            enabledCurrencies: Array(selectedCurrencies),
            iconName: iconName,
            sortOrder: maxOrderInGroup + 1,
            accountGroup: accountGroup
        )

        do {
            try repository.save()
            return true
        } catch {
            return false
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
