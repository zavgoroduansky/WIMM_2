import Testing
@testable import WIMM

@MainActor
struct NewTransactionViewModelTests {

    @Test
    func filtersCategoriesByTransactionKind() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        group.accounts = [account]

        let incomeCategory = TestDataFactory.makeCategory(name: "Salary", kind: .income)
        let expenseCategory = TestDataFactory.makeCategory(name: "Food", kind: .expense)

        let viewModel = NewTransactionViewModel(defaultMode: .expense, repository: MockFinanceRepository())
        viewModel.updateData(
            accountGroups: [group],
            categories: [incomeCategory, expenseCategory],
            defaultCurrency: .eur
        )

        #expect(viewModel.filteredCategories.map(\.name) == ["Food"])

        viewModel.mode = .income
        viewModel.handleModeChange()

        #expect(viewModel.filteredCategories.map(\.name) == ["Salary"])
    }

    @Test
    func saveIncomeUsesInjectedService() throws {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)
        group.accounts = [account]

        let category = TestDataFactory.makeCategory(name: "Salary", kind: .income)

        let repository = MockFinanceRepository()
        let viewModel = NewTransactionViewModel(defaultMode: .income, repository: repository)

        viewModel.updateData(accountGroups: [group], categories: [category], defaultCurrency: .eur)
        viewModel.mode = .income
        viewModel.handleModeChange()
        viewModel.amount = "100"
        viewModel.note = "  test note  "

        let isSaved = viewModel.save()

        #expect(isSaved)
        #expect(repository.createIncomeCalls == 1)
        #expect(repository.lastIncomeAmountMinor == 10_000)
        #expect(repository.lastIncomeCurrency == .eur)
        #expect(repository.lastIncomeCategoryID == category.id)
        #expect(repository.lastIncomeNote == "test note")
    }

    @Test
    func transferRequiresAmountToWhenCurrenciesDiffer() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(name: "From", enabledCurrencies: [.eur], accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", enabledCurrencies: [.usd], accountGroup: group)
        group.accounts = [from, to]

        let viewModel = NewTransactionViewModel(defaultMode: .transfer, repository: MockFinanceRepository())
        viewModel.updateData(accountGroups: [group], categories: [], defaultCurrency: .eur)

        viewModel.mode = .transfer
        viewModel.fromAccountID = from.id
        viewModel.toAccountID = to.id
        viewModel.transferFromCurrency = .eur
        viewModel.transferToCurrency = .usd
        viewModel.amount = "10"
        viewModel.amountTo = ""

        #expect(!viewModel.canSave)

        viewModel.amountTo = "25"
        #expect(viewModel.canSave)
    }

    @Test
    func transferSameCurrencyDoesNotRequireAmountTo() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(name: "From", enabledCurrencies: [.eur], accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", enabledCurrencies: [.eur], accountGroup: group)
        group.accounts = [from, to]

        let viewModel = NewTransactionViewModel(defaultMode: .transfer, repository: MockFinanceRepository())
        viewModel.updateData(accountGroups: [group], categories: [], defaultCurrency: .eur)

        viewModel.mode = .transfer
        viewModel.fromAccountID = from.id
        viewModel.toAccountID = to.id
        viewModel.transferFromCurrency = .eur
        viewModel.transferToCurrency = .eur
        viewModel.amount = "10"
        viewModel.amountTo = ""

        #expect(viewModel.canSave)
    }

    @Test
    func preselectedAccountAndCategoryAreRespected() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let a1 = TestDataFactory.makeAccount(name: "A1", accountGroup: group)
        let a2 = TestDataFactory.makeAccount(name: "A2", accountGroup: group)
        group.accounts = [a1, a2]

        let c1 = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let c2 = TestDataFactory.makeCategory(name: "Salary", kind: .income)

        let viewModel = NewTransactionViewModel(
            defaultMode: .expense,
            preselectedAccountID: a2.id,
            preselectedCategoryID: c1.id,
            repository: MockFinanceRepository()
        )
        viewModel.updateData(accountGroups: [group], categories: [c1, c2], defaultCurrency: .eur)

        #expect(viewModel.accountID == a2.id)
        #expect(viewModel.categoryID == c1.id)
    }

    @Test
    func defaultCurrencySyncFallsBackWhenUnsupported() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(
            name: "Wallet",
            primaryCurrency: .eur,
            enabledCurrencies: [.eur],
            accountGroup: group
        )
        group.accounts = [account]

        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let viewModel = NewTransactionViewModel(defaultMode: .expense, repository: MockFinanceRepository())
        viewModel.updateData(accountGroups: [group], categories: [category], defaultCurrency: .usd)

        #expect(viewModel.transactionCurrency == .eur)
    }

    @Test
    func saveTransferUsesRepository() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(name: "From", enabledCurrencies: [.eur], accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", enabledCurrencies: [.usd], accountGroup: group)
        group.accounts = [from, to]

        let repo = MockFinanceRepository()
        repo.seed(groups: [group], categories: [], transactions: [])

        let viewModel = NewTransactionViewModel(defaultMode: .transfer, repository: repo)
        viewModel.updateData(accountGroups: [group], categories: [], defaultCurrency: .eur)
        viewModel.mode = .transfer
        viewModel.fromAccountID = from.id
        viewModel.toAccountID = to.id
        viewModel.transferFromCurrency = .eur
        viewModel.transferToCurrency = .usd
        viewModel.amount = "10"
        viewModel.amountTo = "20"

        let saved = viewModel.save()

        #expect(saved)
        #expect(repo.createTransferCalls == 1)
        #expect(repo.transactions.count == 2)
    }

    @Test
    func transferCurrenciesChangeClearsAmountToWhenSameCurrency() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(name: "From", enabledCurrencies: [.eur], accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", enabledCurrencies: [.eur], accountGroup: group)
        group.accounts = [from, to]

        let viewModel = NewTransactionViewModel(defaultMode: .transfer, repository: MockFinanceRepository())
        viewModel.updateData(accountGroups: [group], categories: [], defaultCurrency: .eur)
        viewModel.mode = .transfer
        viewModel.fromAccountID = from.id
        viewModel.toAccountID = to.id
        viewModel.transferFromCurrency = .eur
        viewModel.transferToCurrency = .usd
        viewModel.amountTo = "50"

        viewModel.transferToCurrency = .eur
        viewModel.handleTransferCurrenciesChange()

        #expect(viewModel.amountTo.isEmpty)
    }

    @Test
    func accountPickerLabelIncludesGroup() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(name: "Wallet", accountGroup: group)

        let viewModel = NewTransactionViewModel(defaultMode: .expense, repository: MockFinanceRepository())
        let label = viewModel.accountPickerLabel(for: account)

        #expect(label == "Cash • Wallet")
    }

    @Test
    func handleAccountChangeFallsBackToSupportedCurrency() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let account = TestDataFactory.makeAccount(
            name: "Wallet",
            primaryCurrency: .uah,
            enabledCurrencies: [.uah],
            accountGroup: group
        )
        group.accounts = [account]

        let category = TestDataFactory.makeCategory(name: "Food", kind: .expense)
        let viewModel = NewTransactionViewModel(defaultMode: .expense, repository: MockFinanceRepository())
        viewModel.updateData(accountGroups: [group], categories: [category], defaultCurrency: .usd)
        viewModel.accountID = account.id
        viewModel.transactionCurrency = .usd

        viewModel.handleAccountChange()

        #expect(viewModel.transactionCurrency == .uah)
    }

    @Test
    func handleTransferAccountsChangeFallsBackToSupportedCurrency() {
        let group = TestDataFactory.makeAccountGroup(name: "Cash")
        let from = TestDataFactory.makeAccount(
            name: "From",
            primaryCurrency: .eur,
            enabledCurrencies: [.eur],
            accountGroup: group
        )
        let to = TestDataFactory.makeAccount(
            name: "To",
            primaryCurrency: .usd,
            enabledCurrencies: [.usd],
            accountGroup: group
        )
        group.accounts = [from, to]

        let viewModel = NewTransactionViewModel(defaultMode: .transfer, repository: MockFinanceRepository())
        viewModel.updateData(accountGroups: [group], categories: [], defaultCurrency: .uah)
        viewModel.fromAccountID = from.id
        viewModel.toAccountID = to.id
        viewModel.transferFromCurrency = .uah
        viewModel.transferToCurrency = .uah

        viewModel.handleTransferAccountsChange()

        #expect(viewModel.transferFromCurrency == .eur)
        #expect(viewModel.transferToCurrency == .usd)
    }
}
