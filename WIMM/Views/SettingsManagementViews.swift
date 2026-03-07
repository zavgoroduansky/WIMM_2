import SwiftUI
import SwiftData

struct ManageAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\AccountGroup.sortOrder), SortDescriptor(\AccountGroup.name)]) private var accountGroups: [AccountGroup]

    @State private var showAdd = false
    @State private var renamingAccount: Account?
    @State private var renamingGroup: AccountGroup?
    @State private var selectedAccountForCurrencyEdit: Account?

    var body: some View {
        List {
            Section("Account Group Order") {
                ForEach(orderedGroups) { group in
                    HStack {
                        Text(group.name)
                        Spacer()
                        Text("\(group.accounts.count)")
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            modelContext.delete(group)
                            try? modelContext.save()
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Rename") {
                            renamingGroup = group
                        }
                        .tint(.blue)
                    }
                }
                .onMove(perform: moveGroups)
            }

            ForEach(orderedGroups) { group in
                Section(group.name) {
                    ForEach(accounts(in: group)) { account in
                        HStack(alignment: .top) {
                            Label(account.name, systemImage: account.iconName ?? "wallet.pass")
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                ForEach(account.balancesByCurrency, id: \.currency) { item in
                                    Text(Money.format(minor: item.balanceMinor, currency: item.currency))
                                        .foregroundStyle(item.balanceMinor < 0 ? .red : .primary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                modelContext.delete(account)
                                try? modelContext.save()
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Currencies") {
                                selectedAccountForCurrencyEdit = account
                            }
                            .tint(.orange)
                            Button("Rename") {
                                renamingAccount = account
                            }
                            .tint(.blue)
                        }
                    }
                    .onMove { source, destination in
                        moveAccounts(in: group, source: source, destination: destination)
                    }
                }
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddAccountView(accountGroups: orderedGroups)
        }
        .sheet(item: $renamingAccount) { account in
            RenameEntityView(
                title: "Rename Account",
                initialName: account.name
            ) { newName in
                account.name = newName
                try? modelContext.save()
            }
        }
        .sheet(item: $renamingGroup) { group in
            RenameEntityView(
                title: "Rename Account Group",
                initialName: group.name
            ) { newName in
                group.name = newName
                try? modelContext.save()
            }
        }
        .sheet(item: $selectedAccountForCurrencyEdit) { account in
            EditAccountCurrenciesView(account: account)
        }
    }

    private var orderedGroups: [AccountGroup] {
        accountGroups.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func accounts(in group: AccountGroup) -> [Account] {
        group.accounts.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var mutable = orderedGroups
        mutable.move(fromOffsets: source, toOffset: destination)

        for (index, group) in mutable.enumerated() {
            group.sortOrder = index
        }

        try? modelContext.save()
    }

    private func moveAccounts(in group: AccountGroup, source: IndexSet, destination: Int) {
        var mutable = accounts(in: group)
        mutable.move(fromOffsets: source, toOffset: destination)

        for (index, account) in mutable.enumerated() {
            account.sortOrder = index
        }

        try? modelContext.save()
    }
}

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]

    @State private var showAdd = false
    @State private var renamingCategory: Category?

    var body: some View {
        List {
            ForEach(sortedCategories) { category in
                HStack {
                    Text(category.name)
                    Spacer()
                    Text(category.kind.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        modelContext.delete(category)
                        try? modelContext.save()
                    }
                }
                .swipeActions(edge: .leading) {
                    Button("Rename") {
                        renamingCategory = category
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("Categories")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    showAdd = true
                }
            }
        }
        .sheet(isPresented: $showAdd) {
            AddCategoryView()
        }
        .sheet(item: $renamingCategory) { category in
            RenameEntityView(
                title: "Rename Category",
                initialName: category.name
            ) { newName in
                category.name = newName
                try? modelContext.save()
            }
        }
    }

    private var sortedCategories: [Category] {
        categories.sorted { lhs, rhs in
            if lhs.kind == rhs.kind {
                return lhs.name < rhs.name
            }
            return lhs.kind.rawValue < rhs.kind.rawValue
        }
    }
}

private struct EditAccountCurrenciesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let account: Account

    @State private var selected: Set<CurrencyCode> = []
    @State private var primary: CurrencyCode = .eur

    var body: some View {
        NavigationStack {
            Form {
                Section("Enabled Currencies") {
                    ForEach(CurrencyCode.allCases) { currency in
                        Toggle(isOn: Binding(
                            get: { selected.contains(currency) },
                            set: { isOn in
                                if isOn {
                                    selected.insert(currency)
                                } else {
                                    selected.remove(currency)
                                }
                                if !selected.contains(primary), let first = selected.first {
                                    primary = first
                                }
                            }
                        )) {
                            Text("\(currency.displayName) (\(currency.symbol))")
                        }
                    }
                }

                Section("Primary Currency") {
                    Picker("Primary", selection: $primary) {
                        ForEach(Array(selected).sorted(by: { $0.rawValue < $1.rawValue })) { currency in
                            Text("\(currency.displayName) (\(currency.symbol))")
                                .tag(currency)
                        }
                    }
                }
            }
            .navigationTitle("Account Currencies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalSelected = selected.isEmpty ? [primary] : Array(selected)
                        account.primaryCurrency = primary
                        account.enabledCurrencies = finalSelected
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
            .onAppear {
                selected = Set(account.enabledCurrencies)
                if selected.isEmpty {
                    selected.insert(account.primaryCurrency)
                }
                primary = account.primaryCurrency
                if !selected.contains(primary) {
                    selected.insert(primary)
                }
            }
        }
    }
}

private struct RenameEntityView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let initialName: String
    let onSave: (String) -> Void

    @State private var name: String

    init(title: String, initialName: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.initialName = initialName
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $name)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
