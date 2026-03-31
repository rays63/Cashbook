import SwiftUI

struct BookRowCard: View {
    @ObservedObject var book: BookEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(book.name ?? "Untitled Book")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)

                    if let description = book.ownerName?.trimmingCharacters(in: .whitespacesAndNewlines), description.isEmpty == false {
                        Text(description)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Balance")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(AppFormatters.currencyString(for: book.balance))
                        .font(.headline.weight(.bold))
                        .foregroundStyle(book.balance >= 0 ? AppTheme.success : AppTheme.danger)
                }
            }

            Divider()
                .overlay(Color.white.opacity(0.7))

            HStack(spacing: 10) {
                Image(systemName: "clock")
                    .foregroundStyle(AppTheme.accent)
                Text("Updated \(AppFormatters.bookDate.string(from: book.updatedAt ?? .now))")
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText.opacity(0.8))
            }
            .font(.caption.weight(.medium))
        }
        .padding(18)
        .appCardStyle()
    }
}
