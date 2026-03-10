import SwiftUI
import SwiftData

struct SettingsScene: View {
    let modelContext: ModelContext
    let dependencies: AppDependencies

    @StateObject private var viewModel: SettingsViewModel

    init(modelContext: ModelContext, dependencies: AppDependencies) {
        self.modelContext = modelContext
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: dependencies.makeSettingsViewModel())
    }

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            makeManageAccountsView: {
                AnyView(ManageAccountsScene(modelContext: modelContext, dependencies: dependencies))
            },
            makeManageCategoriesView: {
                AnyView(ManageCategoriesScene(modelContext: modelContext, dependencies: dependencies))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    return SettingsScene(modelContext: context, dependencies: dependencies)
}
