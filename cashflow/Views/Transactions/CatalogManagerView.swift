import CoreData
import SwiftUI

struct CatalogManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @ObservedObject var book: BookEntity

    let kind: CatalogKind
    let onSelect: (String) -> Void

    @State private var newName = ""
    @State private var drafts: [NSManagedObjectID: String] = [:]
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section(kind.title) {
                    ForEach(items, id: \.objectID) { item in
                        HStack(spacing: 12) {
                            TextField(kind.singularTitle, text: binding(for: item))
                            Button("Save") {
                                rename(item)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                Section("Add New \(kind.singularTitle)") {
                    TextField("New \(kind.singularTitle)", text: $newName)
                    Button("Add") {
                        addNewItem()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle(kind.editOptionTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Unable to Save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                syncDrafts()
            }
        }
    }

    private var items: [any NamedCatalogItem] {
        switch kind {
        case .category:
            book.categoriesArray.map { $0 as any NamedCatalogItem }
        case .paymentMode:
            book.paymentModesArray.map { $0 as any NamedCatalogItem }
        }
    }

    private func binding(for item: any NamedCatalogItem) -> Binding<String> {
        Binding(
            get: { drafts[item.objectID] ?? item.displayName },
            set: { drafts[item.objectID] = $0 }
        )
    }

    private func syncDrafts() {
        drafts = Dictionary(uniqueKeysWithValues: items.map { ($0.objectID, $0.displayName) })
    }

    private func addNewItem() {
        do {
            let addedName: String
            switch kind {
            case .category:
                addedName = try FinanceCatalogService.addCategory(named: newName, for: book, in: context).wrappedName
            case .paymentMode:
                addedName = try FinanceCatalogService.addPaymentMode(named: newName, for: book, in: context).wrappedName
            }
            newName = ""
            onSelect(addedName)
            syncDrafts()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }

    private func rename(_ item: any NamedCatalogItem) {
        let updatedName = drafts[item.objectID] ?? item.displayName

        do {
            switch kind {
            case .category:
                guard let category = item as? CategoryEntity else { return }
                try FinanceCatalogService.renameCategory(category, to: updatedName, in: context)
                onSelect(category.wrappedName)
            case .paymentMode:
                guard let paymentMode = item as? PaymentModeEntity else { return }
                try FinanceCatalogService.renamePaymentMode(paymentMode, to: updatedName, in: context)
                onSelect(paymentMode.wrappedName)
            }
            syncDrafts()
        } catch {
            context.rollback()
            errorMessage = error.localizedDescription
        }
    }
}

private protocol NamedCatalogItem: AnyObject {
    var objectID: NSManagedObjectID { get }
    var displayName: String { get }
}

extension CategoryEntity: NamedCatalogItem {
    fileprivate var displayName: String { wrappedName }
}

extension PaymentModeEntity: NamedCatalogItem {
    fileprivate var displayName: String { wrappedName }
}
