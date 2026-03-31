import SwiftUI

struct SummaryCardView: View {
    let balance: Double
    let cashIn: Double
    let cashOut: Double
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Overview")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("Book Snapshot")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                Spacer()
                Image(systemName: "chart.line.text.clipboard")
                    .font(.title3)
                    .foregroundStyle(AppTheme.accent)
            }

            HStack(alignment: .top, spacing: 16) {
                metric(title: "Remaining Balance", value: balance, tint: balance >= 0 ? .green : .red)
                metric(title: "Cash In", value: cashIn, tint: .green)
                metric(title: "Cash Out", value: cashOut, tint: .red)
            }

            Button(action: action) {
                HStack {
                    Text("View Report")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.accent)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [AppTheme.accentSoft, Color.white.opacity(0.78)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.8), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow, radius: 18, x: 0, y: 12)
    }

    private func metric(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            Text(AppFormatters.currencyString(for: value))
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
