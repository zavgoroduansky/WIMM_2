import Foundation

protocol DateFormatting {
    func string(from date: Date) -> String
}

extension DateFormatter: DateFormatting {}

enum DateFormatterFactory {
    static func reportsMonthLabel(locale: Locale = .current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }

    static func historySectionTitle(locale: Locale = .current) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }
}
