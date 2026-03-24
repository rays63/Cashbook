import CoreData
import Foundation

enum CatalogServiceError: LocalizedError {
    case emptyName(String)
    case duplicateName(String)

    var errorDescription: String? {
        switch self {
        case .emptyName(let field):
            "\(field) name cannot be empty."
        case .duplicateName(let field):
            "\(field) name already exists."
        }
    }
}

enum FinanceCatalogService {
    static let defaultCategories = ["Sales", "Purchase", "Food", "Fuel", "Utilities", "Salary", "Rent"]
    static let defaultPaymentModes = ["Cash", "Bank", "Card", "UPI"]

    static func seedDefaultsIfNeeded(for book: BookEntity, in context: NSManagedObjectContext) {
        if book.categoriesArray.isEmpty {
            defaultCategories.forEach { createCategory(named: $0, for: book, in: context, isSystem: true) }
        }

        if book.paymentModesArray.isEmpty {
            defaultPaymentModes.forEach { createPaymentMode(named: $0, for: book, in: context, isSystem: true) }
        }
    }

    @discardableResult
    static func findOrCreateCategory(named name: String, for book: BookEntity, in context: NSManagedObjectContext) -> CategoryEntity? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        if let existing = book.categoriesArray.first(where: { $0.wrappedName.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        return createCategory(named: trimmed, for: book, in: context, isSystem: false)
    }

    @discardableResult
    static func findOrCreatePaymentMode(named name: String, for book: BookEntity, in context: NSManagedObjectContext) -> PaymentModeEntity? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return nil }
        if let existing = book.paymentModesArray.first(where: { $0.wrappedName.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            return existing
        }
        return createPaymentMode(named: trimmed, for: book, in: context, isSystem: false)
    }

    @discardableResult
    static func addCategory(named name: String, for book: BookEntity, in context: NSManagedObjectContext) throws -> CategoryEntity {
        let trimmed = try validatedName(name, field: "Category")
        guard book.categoriesArray.contains(where: { $0.wrappedName.caseInsensitiveCompare(trimmed) == .orderedSame }) == false else {
            throw CatalogServiceError.duplicateName("Category")
        }
        let category = createCategory(named: trimmed, for: book, in: context, isSystem: false)
        try context.saveIfNeeded()
        return category
    }

    @discardableResult
    static func addPaymentMode(named name: String, for book: BookEntity, in context: NSManagedObjectContext) throws -> PaymentModeEntity {
        let trimmed = try validatedName(name, field: "Payment mode")
        guard book.paymentModesArray.contains(where: { $0.wrappedName.caseInsensitiveCompare(trimmed) == .orderedSame }) == false else {
            throw CatalogServiceError.duplicateName("Payment mode")
        }
        let paymentMode = createPaymentMode(named: trimmed, for: book, in: context, isSystem: false)
        try context.saveIfNeeded()
        return paymentMode
    }

    static func renameCategory(_ category: CategoryEntity, to name: String, in context: NSManagedObjectContext) throws {
        let trimmed = try validatedName(name, field: "Category")
        if let book = category.book,
           book.categoriesArray.contains(where: { $0 != category && $0.wrappedName.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            throw CatalogServiceError.duplicateName("Category")
        }
        category.name = trimmed
        category.updatedAt = .now
        try context.saveIfNeeded()
    }

    static func renamePaymentMode(_ paymentMode: PaymentModeEntity, to name: String, in context: NSManagedObjectContext) throws {
        let trimmed = try validatedName(name, field: "Payment mode")
        if let book = paymentMode.book,
           book.paymentModesArray.contains(where: { $0 != paymentMode && $0.wrappedName.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            throw CatalogServiceError.duplicateName("Payment mode")
        }
        paymentMode.name = trimmed
        paymentMode.updatedAt = .now
        try context.saveIfNeeded()
    }

    @discardableResult
    private static func createCategory(named name: String, for book: BookEntity, in context: NSManagedObjectContext, isSystem: Bool) -> CategoryEntity {
        let category = CategoryEntity(context: context)
        category.id = UUID()
        category.name = name
        category.createdAt = .now
        category.updatedAt = .now
        category.isSystem = isSystem
        category.book = book
        return category
    }

    @discardableResult
    private static func createPaymentMode(named name: String, for book: BookEntity, in context: NSManagedObjectContext, isSystem: Bool) -> PaymentModeEntity {
        let paymentMode = PaymentModeEntity(context: context)
        paymentMode.id = UUID()
        paymentMode.name = name
        paymentMode.createdAt = .now
        paymentMode.updatedAt = .now
        paymentMode.isSystem = isSystem
        paymentMode.book = book
        return paymentMode
    }

    private static func validatedName(_ name: String, field: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else {
            throw CatalogServiceError.emptyName(field)
        }
        return trimmed
    }
}
