import SwiftUI

struct ReportView: View {
    @EnvironmentObject private var exportSettings: ExportSettingsStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ReportViewModel()

    let book: BookEntity
    @ObservedObject var detailViewModel: BookDetailViewModel

    var body: some View {
        let snapshot = detailViewModel.reportSnapshot(for: viewModel.selectedType)

        ZStack {
            AppBackgroundView()

            List {
                Section {
                    Picker("Report Type", selection: $viewModel.selectedType) {
                        ForEach(ReportType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(AppTheme.listRowFill)

                Section("Summary") {
                    reportMetric("Net Balance", AppFormatters.currencyString(for: snapshot.netBalance))
                    reportMetric("Total Cash In", AppFormatters.currencyString(for: snapshot.totalCashIn))
                    reportMetric("Total Cash Out", AppFormatters.currencyString(for: snapshot.totalCashOut))
                }
                .listRowBackground(AppTheme.listRowFill)

                Section("Rows") {
                    ForEach(snapshot.rows) { row in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(row.title)
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)
                                Spacer()
                                Text(AppFormatters.currencyString(for: row.amount))
                                    .foregroundStyle(row.amount >= 0 ? AppTheme.success : AppTheme.danger)
                            }
                            Text(row.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            if let balance = row.balance {
                                Text("Balance: \(AppFormatters.currencyString(for: balance))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .listRowBackground(AppTheme.listRowFill)

                Section("Export") {
                    NavigationLink("Export Settings") {
                        ExportSettingsView()
                    }
                    Button("Generate PDF") {
                        viewModel.export(book: book, snapshot: snapshot, fields: exportSettings.orderedFields(), asPDF: true)
                    }
                    Button("Generate Excel") {
                        viewModel.export(book: book, snapshot: snapshot, fields: exportSettings.orderedFields(), asPDF: false)
                    }
                }
                .listRowBackground(AppTheme.listRowFill)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Reports")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close") { dismiss() }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.exportedURL != nil },
            set: { if $0 == false { viewModel.exportedURL = nil } }
        )) {
            if let url = viewModel.exportedURL {
                ActivityView(items: [url])
            }
        }
        .alert("Export failed", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private func reportMetric(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText)
        }
    }
}
