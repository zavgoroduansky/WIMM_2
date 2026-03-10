import Foundation

extension Sequence where Element == AccountGroup {
    func sortedByOrderThenName() -> [AccountGroup] {
        sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }
}

extension Sequence where Element == Account {
    func sortedByOrderThenName() -> [Account] {
        sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.name < rhs.name
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }
}

extension Sequence where Element == Category {
    func sortedByName() -> [Category] {
        sorted { $0.name < $1.name }
    }
}
