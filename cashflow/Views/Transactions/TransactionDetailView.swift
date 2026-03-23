import SwiftUI

struct TransactionDetailView: View {
    @ObservedObject var transaction: TransactionEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        List {
            Section("Overview") {
                detailRow("Title", transaction.title ?? "Untitled Entry")
                detailRow("Amount", "\(transaction.transactionKind.amountPrefix)\(AppFormatters.currencyString(for: transaction.amount))")
                detailRow("Type", transaction.transactionKind.title)
                detailRow("Category", transaction.category?.wrappedName ?? "-")
                detailRow("Payment Mode", transaction.paymentMode?.wrappedName ?? "-")
                detailRow("Date", AppFormatters.bookDate.string(from: transaction.occurredAt ?? .now))
                detailRow("Balance After Entry", AppFormatters.currencyString(for: transaction.runningBalance))
                detailRow("Entry By", transaction.editorName ?? "You")
                if let notes = transaction.notes, notes.isEmpty == false {
                    detailRow("Notes", notes)
                }
            }

            Section("Edit History") {
                if transaction.logArray.isEmpty {
                    Text("No history available")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(transaction.logArray, id: \.objectID) { log in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(log.action ?? "Updated")
                                .font(.headline)
                            Text(log.details ?? "")
                                .font(.subheadline)
                            Text(AppFormatters.bookDate.string(from: log.timestamp ?? .now))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Entry Details")
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
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
        }
        .padding(.vertical, 2)
    }
}
