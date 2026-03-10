import SwiftUI
import SwiftData

struct CategoriesScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: CategoriesViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeCategoriesViewModel())
    }

    var body: some View {
        CategoriesView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) },
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
    return CategoriesScene(modelContext: context, dependencies: dependencies)
}
