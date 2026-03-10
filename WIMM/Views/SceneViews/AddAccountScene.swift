import SwiftUI
import SwiftData

struct AddAccountScene: View {
    let dependencies: AppDependencies

    @ObservedObject private var viewModel: AddAccountViewModel

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        guard let viewModel = dependencies.addAccountViewModel else {
            fatalError("AppDependencies not configured.")
        }
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        AddAccountView(
            viewModel: viewModel
        )
    }
}

#Preview {
    let context = PreviewSupport.makeContext()
    let dependencies = PreviewSupport.makeDependencies()
    dependencies.configure(modelContext: context)
    return AddAccountScene(dependencies: dependencies)
}
