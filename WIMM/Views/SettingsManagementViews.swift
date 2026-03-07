import SwiftUI
import SwiftData

struct ManageAccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\AccountGroup.sortOrder), SortDescriptor(\AccountGroup.name)]) private var accountGroups: [AccountGroup]

    @State private var showAdd = false
    @State private var renamingAccount: Account?
    @State private var renamingGroup: AccountGroup?
    @State private var selectedAccountForCurrencyEdit: Account?

    @StateObject private var viewModel = ManageAccountsViewModel()

    var body: some View {
        List {
            Section("Account Group Order") {
                ForEach(viewModel.orderedGroups) { group in
                    HStack {
                        Text(group.name)
                        Spacer()
                        Text("\(group.accounts.count)")
                            .foregroundStyle(.secondary)
                    }
                    .swipeActions(edge: .trailing) {
                        Button("Delete", role: .destructive) {
                            viewModel.deleteGroup(group, in: modelContext)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button("Rename") {
                            renamingGroup = group
                        }
                        .tint(.blue)
                    }
                }
                .onMove { source, destination in
                    viewModel.moveGroups(from: source, to: destination, in: modelContext)
                }
            }

            ForEach(viewModel.orderedGroups) { group in
                Section(group.name) {
                    ForEach(viewModel.accounts(in: group)) { account in
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
                                viewModel.deleteAccount(account, in: modelContext)
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
                        viewModel.moveAccounts(in: group, source: source, destination: destination, in: modelContext)
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
            AddAccountView(accountGroups: viewModel.orderedGroups)
        }
        .sheet(item: $renamingAccount) { account in
            RenameEntityView(
                title: "Rename Account",
                initialName: account.name
            ) { newName in
                viewModel.renameAccount(account, to: newName, in: modelContext)
            }
        }
        .sheet(item: $renamingGroup) { group in
            RenameEntityView(
                title: "Rename Account Group",
                initialName: group.name
            ) { newName in
                viewModel.renameGroup(group, to: newName, in: modelContext)
            }
        }
        .sheet(item: $selectedAccountForCurrencyEdit) { account in
            EditAccountCurrenciesView(account: account)
        }
        .task(id: accountGroupsSyncKey) {
            viewModel.update(accountGroups: accountGroups)
        }
    }
}

struct ManageCategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Category.name)]) private var categories: [Category]

    @State private var showAdd = false
    @State private var renamingCategory: Category?

    @StateObject private var viewModel = ManageCategoriesViewModel()

    var body: some View {
        List {
            ForEach(viewModel.sortedCategories) { category in
                HStack {
                    Text(category.name)
                    Spacer()
                    Text(category.kind.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .swipeActions(edge: .trailing) {
                    Button("Delete", role: .destructive) {
                        viewModel.deleteCategory(category, in: modelContext)
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
                viewModel.renameCategory(category, to: newName, in: modelContext)
            }
        }
        .task(id: categoriesSyncKey) {
            viewModel.update(categories: categories)
        }
    }

    private var categoriesSyncKey: String {
        categories
            .map { "\($0.id.uuidString):\($0.name):\($0.kind.rawValue)" }
            .sorted()
            .joined(separator: "|")
    }
}

private struct EditAccountCurrenciesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let account: Account

    @StateObject private var viewModel = EditAccountCurrenciesViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Enabled Currencies") {
                    ForEach(CurrencyCode.allCases) { currency in
                        Toggle(isOn: Binding(
                            get: { viewModel.selected.contains(currency) },
                            set: { isOn in
                                viewModel.toggleCurrency(currency, isOn: isOn)
                            }
                        )) {
                            Text("\(currency.displayName) (\(currency.symbol))")
                        }
                    }
                }

                Section("Primary Currency") {
                    Picker("Primary", selection: $viewModel.primary) {
                        ForEach(Array(viewModel.selected).sorted(by: { $0.rawValue < $1.rawValue })) { currency in
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
                        viewModel.save(account: account, in: modelContext)
                        dismiss()
                    }
                }
            }
            .onAppear {
                viewModel.applyInitialState(from: account)
            }
        }
    }
}

private extension ManageAccountsView {
    var accountGroupsSyncKey: String {
        accountGroups
            .map { group in
                "\(group.id.uuidString):\(group.sortOrder):\(group.accounts.count)"
            }
            .sorted()
            .joined(separator: "|")
    }
}

private struct RenameEntityView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (String) -> Void

    @StateObject private var viewModel: RenameEntityViewModel

    init(title: String, initialName: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: RenameEntityViewModel(initialName: initialName))
    }

    var body: some View {
        NavigationStack {
            Form {
                TextField("Name", text: $viewModel.name)
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(viewModel.trimmedName)
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
