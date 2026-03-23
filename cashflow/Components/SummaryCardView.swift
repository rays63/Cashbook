import SwiftUI

struct SummaryCardView: View {
    let balance: Double
    let cashIn: Double
    let cashOut: Double
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Summary")
                .font(.headline)

            HStack {
                metric(title: "Net Balance", value: balance, tint: balance >= 0 ? .green : .red)
                Spacer()
                metric(title: "Cash In", value: cashIn, tint: .green)
                Spacer()
                metric(title: "Cash Out", value: cashOut, tint: .red)
            }

            Button("View Report", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.18), Color.green.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
    }

    private func metric(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(AppFormatters.currencyString(for: value))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
        }
    }
}
