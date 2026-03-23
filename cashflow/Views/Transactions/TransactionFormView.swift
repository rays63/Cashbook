import SwiftUI

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: TransactionDraft

    let book: BookEntity
    let title: String
    let onSave: (TransactionDraft) -> Bool

    init(book: BookEntity, initialDraft: TransactionDraft, title: String, onSave: @escaping (TransactionDraft) -> Bool) {
        self.book = book
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Type") {
                    Picker("Entry Type", selection: $draft.type) {
                        ForEach(TransactionKind.allCases) { kind in
                            Text(kind.title).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Transaction") {
                    TextField("Amount", text: $draft.amountText)
                        .keyboardType(.decimalPad)
                    TextField("Title", text: $draft.title)
                    TextField("Category", text: $draft.categoryName)
                    if book.categoriesArray.isEmpty == false {
                        categoryChips(names: book.categoriesArray.map(\.wrappedName), binding: $draft.categoryName)
                    }
                    TextField("Payment Mode", text: $draft.paymentModeName)
                    if book.paymentModesArray.isEmpty == false {
                        categoryChips(names: book.paymentModesArray.map(\.wrappedName), binding: $draft.paymentModeName)
                    }
                    DatePicker("Date & Time", selection: $draft.occurredAt)
                }

                Section("Notes") {
                    TextField("Add notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if onSave(draft) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func categoryChips(names: [String], binding: Binding<String>) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(names, id: \.self) { name in
                    Button(name) {
                        binding.wrappedValue = name
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
