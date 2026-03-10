import SwiftUI
import SwiftData

struct SettingsScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: SettingsViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.settingsViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        SettingsView(
            viewModel: viewModel,
            makeManageAccountsView: {
                AnyView(ManageAccountsScene(dependencies: dependencies))
            },
            makeManageCategoriesView: {
                AnyView(ManageCategoriesScene(dependencies: dependencies))
            }
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return SettingsScene(dependencies: dependencies)
}
