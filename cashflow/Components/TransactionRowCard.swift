import SwiftUI

struct TransactionRowCard: View {
    @ObservedObject var transaction: TransactionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.category?.wrappedName ?? "General")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((transaction.transactionKind == .cashIn ? Color.green : Color.red).opacity(0.12), in: Capsule())

                    Text(transaction.title ?? "Untitled Entry")
                        .font(.headline)
                }

                Spacer()

                Text("\(transaction.transactionKind.amountPrefix)\(AppFormatters.currencyString(for: transaction.amount))")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(transaction.transactionKind == .cashIn ? .green : .red)
            }

            HStack {
                Text("Balance: \(AppFormatters.currencyString(for: transaction.runningBalance))")
                Spacer()
                Text("Entry by \(transaction.editorName ?? "You") at \(AppFormatters.timeOnly.string(from: transaction.occurredAt ?? .now))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
