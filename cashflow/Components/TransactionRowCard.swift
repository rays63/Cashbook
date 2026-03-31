import SwiftUI

struct TransactionRowCard: View {
    @ObservedObject var transaction: TransactionEntry
    var isSelectionMode = false
    var isSelected = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if isSelectionMode {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppTheme.accentSoft : AppTheme.cardFill)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Circle()
                                .stroke(isSelected ? AppTheme.accent : AppTheme.cardStroke, lineWidth: 1.2)
                        )

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                .padding(.top, 3)
            }

            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(transaction.category?.wrappedName ?? "General")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background((transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger).opacity(0.12), in: Capsule())

                        Text(transaction.title ?? "Untitled Entry")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(transaction.transactionKind.title)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("\(transaction.transactionKind.amountPrefix)\(AppFormatters.currencyString(for: transaction.amount))")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                    }
                }

                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(transaction.importedStatementBalance != nil ? "Statement Balance" : "Running Balance")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text(AppFormatters.currencyString(for: transaction.displayBalance))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
                    Spacer()
                    Text("By \(transaction.editorName ?? "You") • \(AppFormatters.timeOnly.string(from: transaction.occurredAt ?? .now))")
                }
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(18)
        .appCardStyle(cornerRadius: 22)
    }
}
