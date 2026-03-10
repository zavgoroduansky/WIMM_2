import SwiftUI
import Charts

struct ReportsChartView: View {
    let items: [ReportsViewModel.CategoryChartItem]
    let chartType: ReportsViewModel.ChartType

    var body: some View {
        if items.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.bar",
                description: Text("No expenses for selected period.")
            )
        } else {
            if chartType == .bar {
                Chart(items) { item in
                    BarMark(
                        x: .value("Category", item.category),
                        y: .value("Amount", item.total)
                    )
                    .foregroundStyle(CategoryColorPalette.color(hex: item.colorHex).gradient)
                }
                .frame(height: 260)
            } else {
                Chart(items) { item in
                    SectorMark(
                        angle: .value("Amount", item.total),
                        innerRadius: .ratio(0.58),
                        angularInset: 1.5
                    )
                    .foregroundStyle(CategoryColorPalette.color(hex: item.colorHex))
                }
                .frame(height: 300)
            }
        }
    }
}

#Preview {
    let items = [
        ReportsViewModel.CategoryChartItem(category: "Food", totalMinor: 1200, colorHex: "#22C55E"),
        ReportsViewModel.CategoryChartItem(category: "Rent", totalMinor: 5400, colorHex: "#3B82F6")
    ]
    return ReportsChartView(items: items, chartType: .bar)
}
