import SwiftUI

struct SummaryCardView: View {
    let balance: Double
    let cashIn: Double
    let cashOut: Double
    let trendPoints: [Double]
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
                metric(title: "Balance", value: balance, tint: balance >= 0 ? .green : .red)
                metric(title: "Cash In", value: cashIn, tint: .green)
                metric(title: "Cash Out", value: cashOut, tint: .red)
            }

            if trendPoints.count >= 2 {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Balance Trend")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                        Text("\(trendPoints.count) points")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    SparklineView(points: trendPoints, tint: balance >= 0 ? AppTheme.accent : AppTheme.danger)
                        .frame(height: 54)
                }
                .padding(14)
                .background(AppTheme.mutedFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button(action: action) {
                HStack {
                    Text("View Report")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.success.opacity(0.92)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    AppTheme.surfaceElevated,
                    AppTheme.accentSoft.opacity(0.95),
                    AppTheme.mutedFill
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.filterStroke, lineWidth: 1)
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
        .padding(14)
        .background(AppTheme.mutedFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct SparklineView: View {
    let points: [Double]
    let tint: Color

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let minValue = points.min() ?? 0
            let maxValue = points.max() ?? 0
            let range = max(maxValue - minValue, 0.001)

            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(tint.opacity(0.06))

                Path { path in
                    for index in points.indices {
                        let x = width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                        let normalized = (points[index] - minValue) / range
                        let y = height - (CGFloat(normalized) * (height - 8)) - 4

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [tint.opacity(0.7), tint],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}
