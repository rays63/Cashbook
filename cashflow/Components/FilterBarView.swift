import SwiftUI

struct FilterBarView: View {
    @Binding var filter: TransactionFilterState
    let categoryOptions: [String]
    let paymentModeOptions: [String]
    @State private var isShowingCustomDateSheet = false
    @State private var draftStartDate = Date()
    @State private var draftEndDate = Date()

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Menu {
                    ForEach(DateRangePreset.allCases.filter { $0 != .custom }) { preset in
                        Button(preset.rawValue) {
                            filter.datePreset = preset
                            if preset != .custom {
                                filter.customStartDate = nil
                                filter.customEndDate = nil
                            }
                        }
                    }
                    Divider()
                    Button("Custom Range") {
                        draftStartDate = filter.customStartDate ?? Date()
                        draftEndDate = filter.customEndDate ?? Date()
                        isShowingCustomDateSheet = true
                    }
                } label: {
                    filterCapsule(title: dateFilterTitle)
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
                    Button {
                        filter = TransactionFilterState()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Clear")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.success.opacity(0.92)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isShowingCustomDateSheet) {
            NavigationStack {
                ZStack {
                    AppBackgroundView()

                    Form {
                        Section("Custom Date Range") {
                            DatePicker("Start Date", selection: $draftStartDate, displayedComponents: .date)
                            DatePicker("End Date", selection: $draftEndDate, in: draftStartDate..., displayedComponents: .date)
                        }
                        .listRowBackground(AppTheme.listRowFill)
                    }
                    .scrollContentBackground(.hidden)
                }
                .navigationTitle("Custom Range")
                .toolbarBackground(.hidden, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            isShowingCustomDateSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Apply") {
                            filter.datePreset = .custom
                            filter.customStartDate = draftStartDate
                            filter.customEndDate = draftEndDate
                            isShowingCustomDateSheet = false
                        }
                    }
                }
            }
        }
    }

    private var dateFilterTitle: String {
        guard filter.datePreset == .custom,
              let start = filter.customStartDate,
              let end = filter.customEndDate else {
            return filter.datePreset.rawValue
        }

        return "\(AppFormatters.shortDate.string(from: start)) - \(AppFormatters.shortDate.string(from: end))"
    }

    private func filterCapsule(title: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "line.3.horizontal.decrease.circle")
            Text(title)
            Image(systemName: "chevron.down")
                .font(.caption2.weight(.bold))
        }
        .font(.subheadline.weight(.medium))
        .foregroundStyle(AppTheme.primaryText)
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(
            LinearGradient(
                colors: [AppTheme.surfaceElevated, AppTheme.filterFill],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay(Capsule().stroke(AppTheme.filterStroke, lineWidth: 1))
        .shadow(color: AppTheme.shadow.opacity(0.45), radius: 10, x: 0, y: 6)
    }
}
