import SwiftUI

struct PDFImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let preview: StatementImportPreview
    let onSave: () -> Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                List {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(preview.sourceURL.lastPathComponent)
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Text("\(preview.transactions.count) transactions ready to import")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(preview.ignoredLineCount) non-transaction lines skipped")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            if preview.duplicateLineCount > 0 {
                                Text("\(preview.duplicateLineCount) duplicates skipped")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Text("Import Summary")
                    }
                    .listRowBackground(AppTheme.listRowFill)

                    Section("Preview") {
                        ForEach(preview.transactions) { item in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(item.description)
                                        .font(.headline)
                                        .foregroundStyle(AppTheme.primaryText)
                                    Spacer()
                                    Text(AppFormatters.currencyString(for: item.transactionAmount))
                                        .foregroundStyle(item.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                                }

                                Text(AppFormatters.bookDate.string(from: item.occurredAt))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)

                                Text("Balance: \(AppFormatters.currencyString(for: item.balance))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listRowBackground(AppTheme.listRowFill)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Import Statement")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave() {
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
