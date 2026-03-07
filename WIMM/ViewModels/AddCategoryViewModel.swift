import Foundation
import Combine
import SwiftData

@MainActor
final class AddCategoryViewModel: ObservableObject {
    @Published var name = ""
    @Published var kind: CategoryKind = .expense

    var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @discardableResult
    func save(in modelContext: ModelContext) -> Bool {
        guard canSave else { return false }

        let category = Category(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            kind: kind
        )

        modelContext.insert(category)
        do {
            try modelContext.save()
            return true
        } catch {
            return false
        }
    }
}
