import SwiftUI

struct ReportsMissingRatesView: View {
    let missingCount: Int

    var body: some View {
        if missingCount > 0 {
            Text("Some values could not be converted (\(missingCount)). Totals are partial.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ReportsMissingRatesView(missingCount: 2)
}
