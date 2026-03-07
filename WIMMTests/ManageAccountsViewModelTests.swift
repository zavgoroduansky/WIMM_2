import Foundation
import SwiftData
import Testing
@testable import WIMM

@MainActor
struct ManageAccountsViewModelTests {
    @Test
    func moveGroupsUpdatesSortOrder() throws {
        let context = try TestDataFactory.makeInMemoryContext()
        let g1 = TestDataFactory.makeAccountGroup(name: "A", sortOrder: 0)
        let g2 = TestDataFactory.makeAccountGroup(name: "B", sortOrder: 1)

        context.insert(g1)
        context.insert(g2)

        let vm = ManageAccountsViewModel()
        vm.update(accountGroups: [g1, g2])

        vm.moveGroups(from: IndexSet(integer: 0), to: 2, in: context)

        #expect(g2.sortOrder == 0)
        #expect(g1.sortOrder == 1)
    }
}
