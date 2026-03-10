import SwiftUI

struct ReportsTotalsView: View {
    let totalExpenseMinor: Int64
    let totalIncomeMinor: Int64
    let currency: CurrencyCode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Totals")
                .font(.headline)
            Text("Expense: \(Money.format(minor: totalExpenseMinor, currency: currency))")
            Text("Income: \(Money.format(minor: totalIncomeMinor, currency: currency))")
            Text("Net: \(Money.format(minor: totalIncomeMinor - totalExpenseMinor, currency: currency))")
        }
    }
}

#Preview {
    ReportsTotalsView(totalExpenseMinor: 1200, totalIncomeMinor: 2500, currency: .eur)
}
