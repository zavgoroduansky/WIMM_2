import SwiftUI
import SwiftData

struct AddAccountView: View {
    enum GroupMode: String, CaseIterable, Identifiable {
        case existing
        case new

        var id: String { rawValue }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let accountGroups: [AccountGroup]

    @AppStorage("defaultCurrency") private var defaultCurrencyRaw = CurrencyCode.eur.rawValue

    @State private var name = ""
    @State private var primaryCurrency: CurrencyCode = .eur
    @State private var selectedCurrencies: Set<CurrencyCode> = [.eur]
    @State private var iconName = "wallet.pass"
    @State private var groupMode: GroupMode = .existing
    @State private var selectedAccountGroupID: UUID?
    @State private var newGroupName = ""

    private let iconOptions = ["wallet.pass", "banknote", "creditcard", "house", "car", "briefcase", "cart", "star"]

    var body: some View {
        NavigationStack {
            Form {
                TextField("Account name", text: $name)

                Section("Currencies") {
                    ForEach(CurrencyCode.allCases) { currency in
                        Toggle(isOn: Binding(
                            get: { selectedCurrencies.contains(currency) },
                            set: { isOn in
                                if isOn {
                                    selectedCurrencies.insert(currency)
                                } else {
                                    selectedCurrencies.remove(currency)
                                }

                                if !selectedCurrencies.contains(primaryCurrency),
                                   let first = selectedCurrencies.first {
                                    primaryCurrency = first
                                }
                            }
                        )) {
                            Text("\(currency.displayName) (\(currency.symbol))")
                        }
                    }

                    Picker("Primary currency", selection: $primaryCurrency) {
                        ForEach(Array(selectedCurrencies).sorted(by: { $0.rawValue < $1.rawValue })) { item in
                            Text("\(item.displayName) (\(item.symbol))").tag(item)
                        }
                    }
                }

                Picker("Group source", selection: $groupMode) {
                    Text("Existing").tag(GroupMode.existing)
                    Text("New").tag(GroupMode.new)
                }
                .pickerStyle(.segmented)

                if groupMode == .existing {
                    Picker("Account group", selection: $selectedAccountGroupID) {
                        ForEach(accountGroups.sorted { $0.sortOrder < $1.sortOrder }) { accountGroup in
                            Text(accountGroup.name).tag(Optional(accountGroup.id))
                        }
                    }
                } else {
                    TextField("New account group", text: $newGroupName)
                }

                Picker("Icon", selection: $iconName) {
                    ForEach(iconOptions, id: \.self) { icon in
                        Label(icon, systemImage: icon).tag(icon)
                    }
                }
            }
            .navigationTitle("New Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let accountGroup: AccountGroup
                        if groupMode == .new {
                            let trimmed = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            let maxGroupOrder = accountGroups.map(\.sortOrder).max() ?? -1
                            let createdGroup = AccountGroup(name: trimmed, sortOrder: maxGroupOrder + 1)
                            modelContext.insert(createdGroup)
                            accountGroup = createdGroup
                        } else {
                            guard let selected = selectedAccountGroup else { return }
                            accountGroup = selected
                        }

                        let maxOrderInGroup = accountGroup.accounts.map(\.sortOrder).max() ?? -1
                        let account = Account(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            primaryCurrency: primaryCurrency,
                            enabledCurrencies: Array(selectedCurrencies),
                            openingBalanceMinor: 0,
                            iconName: iconName,
                            sortOrder: maxOrderInGroup + 1,
                            accountGroup: accountGroup
                        )
                        modelContext.insert(account)
                        try? modelContext.save()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
            .onAppear {
                if selectedAccountGroupID == nil {
                    selectedAccountGroupID = accountGroups.first?.id
                }
                if accountGroups.isEmpty {
                    groupMode = .new
                }

                let defaultCurrency = CurrencyCode(rawValue: defaultCurrencyRaw) ?? .eur
                selectedCurrencies = [defaultCurrency]
                primaryCurrency = defaultCurrency
            }
        }
    }

    private var selectedAccountGroup: AccountGroup? {
        accountGroups.first { $0.id == selectedAccountGroupID }
    }

    private var canSave: Bool {
        let validGroup: Bool
        if groupMode == .new {
            validGroup = !newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } else {
            validGroup = selectedAccountGroup != nil
        }

        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            validGroup &&
            !selectedCurrencies.isEmpty
    }
}
