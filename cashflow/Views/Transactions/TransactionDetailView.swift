import SwiftUI

struct TransactionDetailView: View {
    @ObservedObject var transaction: TransactionEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(transaction.title ?? "Untitled Entry")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(transaction.transactionKind.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                            }
                            Spacer()
                            Text("\(transaction.transactionKind.amountPrefix)\(AppFormatters.currencyString(for: transaction.amount))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                        }

                        Divider()

                        detailRow("Category", transaction.category?.wrappedName ?? "-")
                        detailRow("Payment Mode", transaction.paymentMode?.wrappedName ?? "-")
                        if let goalName = transaction.goal?.wrappedName {
                            detailRow("Goal", goalName)
                        }
                        detailRow("Date", AppFormatters.bookDate.string(from: transaction.occurredAt ?? .now))
                        detailRow("Balance After Entry", AppFormatters.currencyString(for: transaction.runningBalance))
                        detailRow("Entry By", transaction.editorName ?? "You")
                        if let notes = transaction.notes, notes.isEmpty == false {
                            detailRow("Notes", notes)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Overview")
                }

                Section {
                    if transaction.logArray.isEmpty {
                        Text("No history available")
                            .foregroundStyle(AppTheme.secondaryText)
                    } else {
                        ForEach(transaction.logArray, id: \.objectID) { log in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(log.action ?? "Updated")
                                    .font(.headline)
                                    .foregroundStyle(AppTheme.primaryText)
                                Text(log.details ?? "")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                                Text(AppFormatters.bookDate.string(from: log.timestamp ?? .now))
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .listRowBackground(AppTheme.listRowFill)
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Entry Details")
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .foregroundStyle(AppTheme.primaryText)
        }
        .padding(.vertical, 2)
    }
}
