import Foundation
import Combine

@MainActor
final class AddCategoryViewModel: ObservableObject {
    @Published var name = ""
    @Published var kind: CategoryKind = .expense
    @Published var colorHex: String = CategoryColorPalette.defaultHex
    private let repository: FinanceRepositorying

    init(repository: FinanceRepositorying, initialKind: CategoryKind = .expense) {
        self.repository = repository
        self.kind = initialKind
    }

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func save() -> Bool {
        guard canSave else { return false }

        _ = repository.createCategory(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: kind,
            colorHex: colorHex
        )
        do {
            try repository.save()
            return true
        } catch {
            return false
        }
    }
}
