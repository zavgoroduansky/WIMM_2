import SwiftUI
import SwiftData

struct ManageAccountsScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: ManageAccountsViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeManageAccountsViewModel())
    }

    var body: some View {
        ManageAccountsView(
            viewModel: viewModel,
            makeRepository: { dependencies.makeFinanceRepository(modelContext: modelContext) },
            makeAddAccountView: {
                AnyView(AddAccountScene(modelContext: modelContext, dependencies: dependencies))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return ManageAccountsScene(modelContext: context, dependencies: dependencies)
}
