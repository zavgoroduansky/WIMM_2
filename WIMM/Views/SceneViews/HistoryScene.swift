import SwiftUI
import SwiftData

struct HistoryScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: HistoryViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeHistoryViewModel())
    }

    var body: some View {
        HistoryView(
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
    return HistoryScene(modelContext: context, dependencies: dependencies)
}
