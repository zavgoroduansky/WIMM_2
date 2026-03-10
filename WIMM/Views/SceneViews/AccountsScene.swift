import SwiftUI
import SwiftData

struct AccountsScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: AccountsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.accountsViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        AccountsView(
            viewModel: viewModel,
            makeBalanceService: { dependencies.makeAccountGroupBalanceService() },
            makeNewTransactionView: { mode, preselectedAccountID, preselectedCategoryID in
                AnyView(NewTransactionScene(
                    dependencies: dependencies,
                    defaultMode: mode,
                    preselectedAccountID: preselectedAccountID,
                    preselectedCategoryID: preselectedCategoryID
                ))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return AccountsScene(dependencies: dependencies)
}
