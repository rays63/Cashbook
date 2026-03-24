import SwiftUI

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var book: BookEntity
    @State private var draft: TransactionDraft
    @State private var isShowingCategoryManager = false
    @State private var isShowingPaymentModeManager = false

    let title: String
    let onSave: (TransactionDraft) -> Bool

    private let emptyCategoryTag = "__none_category__"
    private let emptyPaymentTag = "__none_payment__"
    private let editCategoryTag = "__edit_category__"
    private let editPaymentTag = "__edit_payment__"

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
                    Picker("Category", selection: categorySelectionBinding) {
                        Text("Select Category").tag(emptyCategoryTag)
                        ForEach(book.categoriesArray.map(\.wrappedName), id: \.self) { name in
                            Text(name).tag(name)
                        }
                        Text(CatalogKind.category.editOptionTitle).tag(editCategoryTag)
                    }
                    .pickerStyle(.menu)

                    Picker("Payment Mode", selection: paymentModeSelectionBinding) {
                        Text("Select Payment Mode").tag(emptyPaymentTag)
                        ForEach(book.paymentModesArray.map(\.wrappedName), id: \.self) { name in
                            Text(name).tag(name)
                        }
                        Text(CatalogKind.paymentMode.editOptionTitle).tag(editPaymentTag)
                    }
                    .pickerStyle(.menu)
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
        .sheet(isPresented: $isShowingCategoryManager) {
            CatalogManagerView(book: book, kind: .category) { selectedName in
                draft.categoryName = selectedName
            }
        }
        .sheet(isPresented: $isShowingPaymentModeManager) {
            CatalogManagerView(book: book, kind: .paymentMode) { selectedName in
                draft.paymentModeName = selectedName
            }
        }
    }

    private var categorySelectionBinding: Binding<String> {
        Binding(
            get: { draft.categoryName.isEmpty ? emptyCategoryTag : draft.categoryName },
            set: { selected in
                if selected == editCategoryTag {
                    isShowingCategoryManager = true
                } else if selected == emptyCategoryTag {
                    draft.categoryName = ""
                } else {
                    draft.categoryName = selected
                }
            }
        )
    }

    private var paymentModeSelectionBinding: Binding<String> {
        Binding(
            get: { draft.paymentModeName.isEmpty ? emptyPaymentTag : draft.paymentModeName },
            set: { selected in
                if selected == editPaymentTag {
                    isShowingPaymentModeManager = true
                } else if selected == emptyPaymentTag {
                    draft.paymentModeName = ""
                } else {
                    draft.paymentModeName = selected
                }
            }
        )
    }
}
