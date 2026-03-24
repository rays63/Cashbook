import SwiftUI

struct FilterBarView: View {
    @Binding var filter: TransactionFilterState
    let categoryOptions: [String]
    let paymentModeOptions: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    Picker("Date", selection: $filter.datePreset) {
                        ForEach(DateRangePreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                } label: {
                    filterCapsule(title: filter.datePreset.rawValue)
                }

                Menu {
                    Button("All Types") { filter.kind = nil }
                    Divider()
                    ForEach(TransactionKind.allCases) { kind in
                        Button(kind.title) { filter.kind = kind }
                    }
                } label: {
                    filterCapsule(title: filter.kind?.title ?? "Entry Type")
                }

                Menu {
                    ForEach(categoryOptions, id: \.self) { option in
                        Button(option) { filter.categoryName = option }
                    }
                } label: {
                    filterCapsule(title: filter.categoryName == "All" ? "Category" : filter.categoryName)
                }

                Menu {
                    ForEach(paymentModeOptions, id: \.self) { option in
                        Button(option) { filter.paymentModeName = option }
                    }
                } label: {
                    filterCapsule(title: filter.paymentModeName == "All" ? "Payment Mode" : filter.paymentModeName)
                }

                if filter.isActive {
                    Button("Clear") {
                        filter = TransactionFilterState()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                }
            }
            .padding(.horizontal)
        }
    }

    private func filterCapsule(title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
            Text(title)
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(AppTheme.primaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.78), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.75), lineWidth: 1))
    }
}
