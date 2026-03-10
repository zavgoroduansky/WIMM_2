import Foundation
import SwiftData
import Combine

@MainActor
final class AppDependencies: ObservableObject {
    func makeFinanceRepository(modelContext: ModelContext) -> FinanceRepositorying {
        SwiftDataFinanceRepository(modelContext: modelContext)
    }

    func makeAccountsViewModel(modelContext: ModelContext) -> AccountsViewModel {
        AccountsViewModel(repository: makeFinanceRepository(modelContext: modelContext))
    }

    func makeAccountGroupBalanceService() -> AccountGroupBalanceServicing {
        AccountGroupBalanceService(rateProvider: FrankfurterRateProvider())
    }

    func makeCategoriesViewModel() -> CategoriesViewModel {
        CategoriesViewModel()
    }

    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel()
    }

    func makeReportsViewModel() -> ReportsViewModel {
        ReportsViewModel(rateProvider: FrankfurterRateProvider())
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel()
    }

    func makeManageAccountsViewModel() -> ManageAccountsViewModel {
        ManageAccountsViewModel()
    }

    func makeManageCategoriesViewModel() -> ManageCategoriesViewModel {
        ManageCategoriesViewModel()
    }

    func makeAddAccountViewModel() -> AddAccountViewModel {
        AddAccountViewModel()
    }

    func makeAddCategoryViewModel(initialKind: CategoryKind) -> AddCategoryViewModel {
        let vm = AddCategoryViewModel()
        vm.kind = initialKind
        return vm
    }

    func makeNewTransactionViewModel(
        defaultMode: NewTransactionViewModel.TransactionMode,
        preselectedAccountID: UUID?,
        preselectedCategoryID: UUID?
    ) -> NewTransactionViewModel {
        NewTransactionViewModel(
            defaultMode: defaultMode,
            preselectedAccountID: preselectedAccountID,
            preselectedCategoryID: preselectedCategoryID,
            transactionService: TransactionService()
        )
    }
}
