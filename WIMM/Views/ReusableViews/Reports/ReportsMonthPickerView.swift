import SwiftUI

struct ReportsMonthPickerView: View {
    let monthOptions: [Date]
    let labelProvider: (Date) -> String
    @Binding var selectedMonthStart: Date

    var body: some View {
        Picker("Month", selection: $selectedMonthStart) {
            ForEach(monthOptions, id: \.self) { month in
                Text(labelProvider(month)).tag(month)
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    ReportsMonthPickerView(
        monthOptions: [Date()],
        labelProvider: { _ in "March 2026" },
        selectedMonthStart: .constant(Date())
    )
}
