import SwiftUI

struct GoalFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: GoalDraft

    let title: String
    let onSave: (GoalDraft) -> Bool

    init(title: String, initialDraft: GoalDraft, onSave: @escaping (GoalDraft) -> Bool) {
        self.title = title
        self.onSave = onSave
        _draft = State(initialValue: initialDraft)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Form {
                    Section("Goal") {
                        TextField("Goal name", text: $draft.name)
                        TextField("Budget", text: $draft.budgetText)
                            .keyboardType(.decimalPad)
                    }
                    .listRowBackground(AppTheme.listRowFill)

                    Section("Deadline") {
                        Toggle("Add deadline", isOn: $draft.hasDeadline)
                        if draft.hasDeadline {
                            DatePicker("Deadline", selection: $draft.deadline, displayedComponents: .date)
                        }
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
                        if onSave(draft) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}
