import SwiftUI

struct BookRowCard: View {
    @ObservedObject var book: BookEntity

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(book.name ?? "Untitled Book")
                    .font(.headline)
                Spacer()
                Text(AppFormatters.currencyString(for: book.balance))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(book.balance >= 0 ? .green : .red)
            }

            HStack(spacing: 12) {
                Label(book.ownerName ?? "You", systemImage: "person.crop.circle")
                Spacer()
                Label(AppFormatters.bookDate.string(from: book.updatedAt ?? .now), systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}
