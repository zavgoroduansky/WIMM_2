import SwiftUI
import SwiftData

struct ManageAccountsScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: ManageAccountsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.manageAccountsViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        ManageAccountsView(
            viewModel: viewModel,
            makeAddAccountView: {
                AnyView(AddAccountScene(dependencies: dependencies))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return ManageAccountsScene(dependencies: dependencies)
}
