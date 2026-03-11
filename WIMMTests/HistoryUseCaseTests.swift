import Foundation
import Testing
@testable import WIMM

@MainActor
struct HistoryUseCaseTests {
    @Test
    func makeEntriesGroupsTransfer() {
        let group = TestDataFactory.makeAccountGroup(name: "Main")
        let from = TestDataFactory.makeAccount(name: "From", accountGroup: group)
        let to = TestDataFactory.makeAccount(name: "To", accountGroup: group)
        group.accounts = [from, to]

        let transferId = UUID()
        let expense = Transaction(
            kind: .expense,
            amountMinor: 1_000,
            currency: .eur,
            date: Date(timeIntervalSince1970: 0),
            transferGroupId: transferId,
            account: from,
            category: nil
        )
        let income = Transaction(
            kind: .income,
            amountMinor: 1_000,
            currency: .eur,
            date: Date(timeIntervalSince1970: 0),
            transferGroupId: transferId,
            account: to,
            category: nil
        )

        let useCase = HistoryUseCase(
            calendar: Calendar.current,
            sectionTitleFormatter: DateFormatterFactory.historySectionTitle()
        )
        let entries = useCase.makeEntries(from: [expense, income])

        #expect(entries.count == 1)
        #expect(entries.first?.tone == .transfer)
        #expect(entries.first?.transferGroupID == transferId)
    }

    @Test
    func makeSectionsSortsByDayDesc() {
        let calendar = Calendar.current
        let formatter = DateFormatterFactory.historySectionTitle()
        let useCase = HistoryUseCase(calendar: calendar, sectionTitleFormatter: formatter)

        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        let entries = [
            HistoryEntry(id: UUID(), title: "A", amountText: "1", tone: .expense, date: yesterday, note: nil, transactionID: UUID(), transferGroupID: nil),
            HistoryEntry(id: UUID(), title: "B", amountText: "2", tone: .expense, date: today, note: nil, transactionID: UUID(), transferGroupID: nil)
        ]

        let sections = useCase.makeSections(from: entries)

        #expect(sections.count == 2)
        #expect(sections.first?.date == calendar.startOfDay(for: today))
    }

    @Test
    func sectionTitleUsesFormatterForOlderDates() {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy"
        let useCase = HistoryUseCase(calendar: calendar, sectionTitleFormatter: formatter)

        let date = Date(timeIntervalSince1970: 0)
        let title = useCase.sectionTitle(for: date, now: Date(timeIntervalSince1970: 100000))

        #expect(title == formatter.string(from: date))
    }
}
