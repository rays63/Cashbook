import CoreData
import Foundation

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
}
