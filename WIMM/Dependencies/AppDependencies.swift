import Foundation
import SwiftData
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    @Published private(set) var isConfigured = false
    private(set) var repository: FinanceRepositorying?
    private(set) var accountsViewModel: AccountsViewModel?
    private(set) var categoriesViewModel: CategoriesViewModel?
    private(set) var historyViewModel: HistoryViewModel?
    private(set) var reportsViewModel: ReportsViewModel?
    private(set) var settingsViewModel: SettingsViewModel?
    private(set) var manageAccountsViewModel: ManageAccountsViewModel?
    private(set) var manageCategoriesViewModel: ManageCategoriesViewModel?
    private(set) var addAccountViewModel: AddAccountViewModel?

    func configure(modelContext: ModelContext) {
        guard !isConfigured else { return }

        let transactionService = TransactionService()
        let repo = SwiftDataFinanceRepository(modelContext: modelContext, transactionService: transactionService)
        repository = repo

        accountsViewModel = AccountsViewModel(repository: repo)
        categoriesViewModel = CategoriesViewModel(repository: repo)
        let calendar = Calendar.current
        let historyFormatter = DateFormatterFactory.historySectionTitle()
        let historyUseCase = HistoryUseCase(calendar: calendar, sectionTitleFormatter: historyFormatter)
        historyViewModel = HistoryViewModel(repository: repo, useCase: historyUseCase)

        let exchangeCache = ExchangeRateCache()
        let rateProvider = FrankfurterRateProvider(
            session: .shared,
            cache: exchangeCache,
            calendar: calendar
        )
        let reportsUseCase = ReportsUseCase(rateProvider: rateProvider, calendar: calendar)
        let reportsMonthFormatter = DateFormatterFactory.reportsMonthLabel()
        reportsViewModel = ReportsViewModel(
            repository: repo,
            useCase: reportsUseCase,
            monthLabelFormatter: reportsMonthFormatter
        )
        settingsViewModel = SettingsViewModel()
        manageAccountsViewModel = ManageAccountsViewModel(repository: repo)
        manageCategoriesViewModel = ManageCategoriesViewModel(repository: repo)
        addAccountViewModel = AddAccountViewModel(repository: repo)

        isConfigured = true
    }

    func makeAccountGroupBalanceService() -> AccountGroupBalanceServicing {
        let calendar = Calendar.current
        let rateProvider = FrankfurterRateProvider(
            session: .shared,
            cache: ExchangeRateCache(),
            calendar: calendar
        )
        return AccountGroupBalanceService(rateProvider: rateProvider)
    }

    func makeAddCategoryViewModel(initialKind: CategoryKind) -> AddCategoryViewModel {
        guard let repo = repository else {
            fatalError("AppDependencies not configured.")
        }
        return AddCategoryViewModel(repository: repo, initialKind: initialKind)
    }

    func makeNewTransactionViewModel(
        defaultMode: NewTransactionViewModel.TransactionMode,
        preselectedAccountID: UUID?,
        preselectedCategoryID: UUID?
    ) -> NewTransactionViewModel {
        guard let repo = repository else {
            fatalError("AppDependencies not configured.")
        }
        return NewTransactionViewModel(
            defaultMode: defaultMode,
            preselectedAccountID: preselectedAccountID,
            preselectedCategoryID: preselectedCategoryID,
            repository: repo
        )
    }
}
