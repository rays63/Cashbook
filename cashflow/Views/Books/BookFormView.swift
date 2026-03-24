import SwiftUI

struct BookFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var ownerName: String

    let title: String
    let onSave: (String, String) -> Void

    init(title: String, initialName: String, initialOwnerName: String, onSave: @escaping (String, String) -> Void) {
        self.title = title
        self.onSave = onSave
        _name = State(initialValue: initialName)
        _ownerName = State(initialValue: initialOwnerName)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Form {
                    Section("Book Details") {
                        TextField("Book name", text: $name)
                        TextField("Owner name", text: $ownerName)
                    }
                    .listRowBackground(AppTheme.listRowFill)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, ownerName)
                        dismiss()
                    }
                }
            }
        }
    }
}
