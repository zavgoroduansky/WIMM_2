import SwiftUI
import SwiftData

struct HistoryScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: HistoryViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.historyViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        HistoryView(
            viewModel: viewModel,
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
    return HistoryScene(dependencies: dependencies)
}
