import SwiftUI
import SwiftData

struct NewTransactionScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies
    let defaultMode: NewTransactionViewModel.TransactionMode
    let preselectedAccountID: UUID?
    let preselectedCategoryID: UUID?

    @StateObject private var viewModel: NewTransactionViewModel

    init(
        modelContext: ModelContext,
        dependencies: AppDependencies,
        defaultMode: NewTransactionViewModel.TransactionMode = .expense,
        preselectedAccountID: UUID? = nil,
        preselectedCategoryID: UUID? = nil
    ) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        self.defaultMode = defaultMode
        self.preselectedAccountID = preselectedAccountID
        self.preselectedCategoryID = preselectedCategoryID
        _viewModel = StateObject(
            wrappedValue: dependencies.makeNewTransactionViewModel(
                defaultMode: defaultMode,
                preselectedAccountID: preselectedAccountID,
                preselectedCategoryID: preselectedCategoryID
            )
        )
    }

    var body: some View {
        NewTransactionView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return NewTransactionScene(modelContext: context, dependencies: dependencies, defaultMode: .expense)
}
