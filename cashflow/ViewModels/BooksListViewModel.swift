import Combine
import CoreData
import Foundation

@MainActor
final class BooksListViewModel: ObservableObject {
    @Published var books: [BookEntity] = []
    @Published var searchText = ""
    @Published var sortOption: BookSortOption = .updatedAt
    @Published var errorMessage: String?

    private weak var context: NSManagedObjectContext?
    private var observer: AnyCancellable?
    private var isConfigured = false

    func configure(context: NSManagedObjectContext) {
        guard isConfigured == false else { return }
        self.context = context
        isConfigured = true
        refresh()

        observer = NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: context)
            .sink { [weak self] _ in
                self?.refresh()
            }
    }

    var filteredBooks: [BookEntity] {
        let searched = books.filter {
            searchText.isEmpty || ($0.name ?? "").localizedCaseInsensitiveContains(searchText)
        }

        switch sortOption {
        case .updatedAt:
            return searched.sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
        case .name:
            return searched.sorted { ($0.name ?? "").localizedCaseInsensitiveCompare($1.name ?? "") == .orderedAscending }
        case .balance:
            return searched.sorted { $0.balance > $1.balance }
        }
    }

    func createBook(name: String, ownerName: String) {
        guard let context else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false, trimmedOwner.isEmpty == false else {
            errorMessage = "Book name and owner are required."
            return
        }

        let book = BookEntity(context: context)
        book.id = UUID()
        book.name = trimmedName
        book.ownerName = trimmedOwner
        book.createdAt = .now
        book.updatedAt = .now

        FinanceCatalogService.seedDefaultsIfNeeded(for: book, in: context)
        saveContext(context, failure: "Unable to create the book.")
    }

    func updateBook(_ book: BookEntity, name: String, ownerName: String) {
        guard let context else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOwner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedName.isEmpty == false, trimmedOwner.isEmpty == false else {
            errorMessage = "Book name and owner are required."
            return
        }

        book.name = trimmedName
        book.ownerName = trimmedOwner
        book.updatedAt = .now
        saveContext(context, failure: "Unable to update the book.")
    }

    func deleteBooks(at offsets: IndexSet) {
        guard let context else { return }
        offsets.map { filteredBooks[$0] }.forEach(context.delete)
        saveContext(context, failure: "Unable to delete the selected book.")
    }

    func deleteBook(_ book: BookEntity) {
        guard let context else { return }
        context.delete(book)
        saveContext(context, failure: "Unable to delete the book.")
    }

    func dismissError() {
        errorMessage = nil
    }

    private func refresh() {
        guard let context else { return }
        let request = BookEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \BookEntity.updatedAt, ascending: false)]
        do {
            books = try context.fetch(request)
        } catch {
            errorMessage = "Unable to load books."
        }
    }

    private func saveContext(_ context: NSManagedObjectContext, failure: String) {
        do {
            try context.saveIfNeeded()
            refresh()
        } catch {
            context.rollback()
            errorMessage = failure
        }
    }
}
