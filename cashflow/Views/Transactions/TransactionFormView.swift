import SwiftUI

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var book: BookEntity
    @State private var draft: TransactionDraft
    @State private var isShowingCategoryManager = false
    @State private var isShowingPaymentModeManager = false
    @State private var inlineErrorMessage: String?

    let title: String
    let goalOptions: [String]
    let onSave: (TransactionDraft) -> Bool

    private let emptyCategoryTag = "__none_category__"
    private let emptyPaymentTag = "__none_payment__"
    private let editCategoryTag = "__edit_category__"
    private let editPaymentTag = "__edit_payment__"

    init(book: BookEntity, initialDraft: TransactionDraft, title: String, goalOptions: [String] = [], onSave: @escaping (TransactionDraft) -> Bool) {
        self.book = book
        self.title = title
        self.goalOptions = goalOptions
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Form {
                    if let inlineErrorMessage {
                        Section {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(inlineErrorMessage)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(AppTheme.primaryText)
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(AppTheme.listRowFill)
                    }

                    Section("Type") {
                        Picker("Entry Type", selection: $draft.type) {
                            ForEach(TransactionKind.allCases) { kind in
                                Text(kind.title).tag(kind)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(AppTheme.listRowFill)

                    Section("Transaction") {
                        TextField("Amount", text: $draft.amountText)
                            .keyboardType(.decimalPad)
                            .onChange(of: draft.amountText) { _, _ in clearInlineError() }
                        TextField("Title", text: $draft.title)
                            .onChange(of: draft.title) { _, _ in clearInlineError() }
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

                        if draft.type == .cashIn {
                            Picker("Goal", selection: goalSelectionBinding) {
                                Text("No Goal").tag(emptyGoalTag)
                                ForEach(goalOptions, id: \.self) { name in
                                    Text(name).tag(name)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        DatePicker("Date & Time", selection: $draft.occurredAt)
                    }
                    .listRowBackground(AppTheme.listRowFill)

                    Section("Notes") {
                        TextField("Add notes", text: $draft.notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    .listRowBackground(AppTheme.listRowFill)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard validateDraft() == nil else { return }
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
                clearInlineError()
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

    private let emptyGoalTag = "__none_goal__"

    private var paymentModeSelectionBinding: Binding<String> {
        Binding(
            get: { draft.paymentModeName.isEmpty ? emptyPaymentTag : draft.paymentModeName },
            set: { selected in
                clearInlineError()
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

    private var goalSelectionBinding: Binding<String> {
        Binding(
            get: { draft.goalName.isEmpty ? emptyGoalTag : draft.goalName },
            set: { selected in
                clearInlineError()
                draft.goalName = selected == emptyGoalTag ? "" : selected
            }
        )
    }

    private func validateDraft() -> String? {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCategory = draft.categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPaymentMode = draft.paymentModeName.trimmingCharacters(in: .whitespacesAndNewlines)

        if draft.amountValue == nil || (draft.amountValue ?? 0) <= 0 {
            inlineErrorMessage = "Enter a valid amount greater than zero."
        } else if trimmedTitle.isEmpty {
            inlineErrorMessage = "Title is required."
        } else if trimmedCategory.isEmpty {
            inlineErrorMessage = "Category is required."
        } else if trimmedPaymentMode.isEmpty {
            inlineErrorMessage = "Payment mode is required."
        } else {
            inlineErrorMessage = nil
        }

        return inlineErrorMessage
    }

    private func clearInlineError() {
        if inlineErrorMessage != nil {
            inlineErrorMessage = nil
        }
    }
}
