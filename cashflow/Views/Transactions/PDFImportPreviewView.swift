import SwiftUI

struct PDFImportPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingDuplicates = false

    let preview: StatementImportPreview
    let onSave: () -> Bool

    private var isAllDuplicatesState: Bool {
        preview.transactions.isEmpty && preview.duplicateLineCount > 0
    }

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
                            Text(isAllDuplicatesState ? "No new transactions are available to import" : "\(preview.transactions.count) transactions ready to import")
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("\(preview.ignoredLineCount) non-transaction lines skipped")
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                            if preview.duplicateLineCount > 0 {
                                Button {
                                    isShowingDuplicates = true
                                } label: {
                                    HStack(spacing: 6) {
                                        Text("\(preview.duplicateLineCount) duplicates skipped")
                                        Image(systemName: "chevron.right")
                                            .font(.caption2.weight(.semibold))
                                    }
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(AppTheme.accent)
                                }
                                .buttonStyle(.plain)
                            }
                            if let openingBalance = preview.openingBalance {
                                Text("Opening balance: \(AppFormatters.currencyString(for: openingBalance))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            if let closingBalance = preview.closingBalance {
                                Text("Closing balance: \(AppFormatters.currencyString(for: closingBalance))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                        }
                        .padding(.vertical, 6)
                    } header: {
                        Text("Import Summary")
                    }
                    .listRowBackground(AppTheme.listRowFill)

                    if isAllDuplicatesState {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.title3)
                                        .foregroundStyle(AppTheme.accent)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Everything in this statement is already in this book.")
                                            .font(.headline)
                                            .foregroundStyle(AppTheme.primaryText)
                                        Text("You can review the skipped duplicates below and close this screen.")
                                            .font(.subheadline)
                                            .foregroundStyle(AppTheme.secondaryText)
                                    }
                                }

                                Button {
                                    isShowingDuplicates = true
                                } label: {
                                    HStack {
                                        Text("View Duplicate Details")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(AppTheme.accent)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.cardFill, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(AppTheme.listRowFill)
                    } else {
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Import Statement")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isAllDuplicatesState ? "Close" : "Cancel") { dismiss() }
                }
                if isAllDuplicatesState == false {
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
        .sheet(isPresented: $isShowingDuplicates) {
            DuplicateTransactionsView(transactions: preview.duplicateTransactions)
        }
    }
}

private struct DuplicateTransactionsView: View {
    @Environment(\.dismiss) private var dismiss

    let transactions: [ImportedStatementTransaction]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                List {
                    Section {
                        Text("\(transactions.count) duplicate transactions were skipped during import.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                            .padding(.vertical, 6)
                    }
                    .listRowBackground(AppTheme.listRowFill)

                    Section("Skipped Duplicates") {
                        ForEach(transactions) { item in
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
            .navigationTitle("Skipped Duplicates")
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
