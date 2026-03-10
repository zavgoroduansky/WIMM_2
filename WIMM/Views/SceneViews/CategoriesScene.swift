import SwiftUI
import SwiftData

struct CategoriesScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: CategoriesViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.categoriesViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        CategoriesView(
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
    return CategoriesScene(dependencies: dependencies)
}
