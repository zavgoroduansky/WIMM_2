import SwiftUI
import SwiftData

struct AccountsScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: AccountsViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: dependencies.makeAccountsViewModel(modelContext: modelContext)
        )
    }

    var body: some View {
        AccountsView(
            viewModel: viewModel,
            makeBalanceService: { dependencies.makeAccountGroupBalanceService() },
            makeNewTransactionView: { mode, preselectedAccountID, preselectedCategoryID in
                AnyView(NewTransactionScene(
                    modelContext: modelContext,
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
    return AccountsScene(modelContext: context, dependencies: dependencies)
}
