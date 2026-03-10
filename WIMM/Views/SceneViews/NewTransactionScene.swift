import SwiftUI
import SwiftData

struct NewTransactionScene: View {
    let dependencies: AppDependencies
    let defaultMode: NewTransactionViewModel.TransactionMode
    let preselectedAccountID: UUID?
    let preselectedCategoryID: UUID?

    @StateObject private var viewModel: NewTransactionViewModel

    init(
        dependencies: AppDependencies,
        defaultMode: NewTransactionViewModel.TransactionMode = .expense,
        preselectedAccountID: UUID? = nil,
        preselectedCategoryID: UUID? = nil
    ) {
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
            viewModel: viewModel
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return NewTransactionScene(dependencies: dependencies, defaultMode: .expense)
}
