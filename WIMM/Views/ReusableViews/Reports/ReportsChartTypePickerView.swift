import SwiftUI

struct ReportsChartTypePickerView: View {
    @Binding var chartType: ReportsViewModel.ChartType

    var body: some View {
        Picker("Chart Type", selection: $chartType) {
            ForEach(ReportsViewModel.ChartType.allCases) { type in
                Text(type.title).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    ReportsChartTypePickerView(chartType: .constant(.bar))
}
