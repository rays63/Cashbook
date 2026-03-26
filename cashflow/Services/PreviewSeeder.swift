import CoreData
import Foundation

enum PreviewSeeder {
    static func seedIfNeeded(in context: NSManagedObjectContext) {
        let request = BookEntity.fetchRequest()
        request.fetchLimit = 1

        if let count = try? context.count(for: request), count > 0 {
            return
        }

        let now = Date()
        let book = BookEntity(context: context)
        book.id = UUID()
        book.name = "Daily CashBook"
        book.ownerName = "Riya"
        book.createdAt = now.addingTimeInterval(-86_400 * 12)
        book.updatedAt = now

        let categories = ["Sales", "Supplies", "Fuel", "Snacks", "Salary"]
        categories.forEach { name in
            let item = CategoryEntity(context: context)
            item.id = UUID()
            item.name = name
            item.createdAt = now
            item.updatedAt = now
            item.isSystem = true
            item.book = book
        }

        let modes = ["Cash", "Bank", "Card", "UPI"]
        modes.forEach { name in
            let item = PaymentModeEntity(context: context)
            item.id = UUID()
            item.name = name
            item.createdAt = now
            item.updatedAt = now
            item.isSystem = true
            item.book = book
        }

        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.name = "Emergency Fund"
        goal.targetAmount = 5000
        goal.deadline = now.addingTimeInterval(86_400 * 60)
        goal.createdAt = now
        goal.updatedAt = now
        goal.book = book

        let samples: [(String, Double, TransactionKind, String, String, TimeInterval)] = [
            ("Opening Balance", 1200, .cashIn, "Sales", "Cash", -86_400 * 5),
            ("Office Supplies", 180, .cashOut, "Supplies", "Card", -86_400 * 4.5),
            ("Walk-in Sale", 560, .cashIn, "Sales", "UPI", -86_400 * 3),
            ("Fuel Refill", 90, .cashOut, "Fuel", "Cash", -86_400 * 1.2),
            ("Snack Counter", 220, .cashIn, "Snacks", "Cash", -3600 * 4)
        ]

        samples.forEach { sample in
            let tx = TransactionEntry(context: context)
            tx.id = UUID()
            tx.title = sample.0
            tx.amount = sample.1
            tx.transactionKind = sample.2
            tx.occurredAt = now.addingTimeInterval(sample.5)
            tx.createdAt = tx.occurredAt
            tx.updatedAt = tx.occurredAt
            tx.editorName = book.ownerName
            tx.notes = sample.0 == "Fuel Refill" ? "Travel expense" : ""
            tx.book = book
            tx.category = book.categoriesArray.first(where: { $0.name == sample.3 })
            tx.paymentMode = book.paymentModesArray.first(where: { $0.name == sample.4 })
            if sample.2 == .cashIn {
                tx.goal = goal
            }

            let log = TransactionLog(context: context)
            log.id = UUID()
            log.action = "Created"
            log.details = "Transaction added by \(book.ownerName ?? "You")"
            log.timestamp = tx.createdAt
            log.transaction = tx
        }

        TransactionBalanceService.recalculateBalances(for: book)
        try? context.saveIfNeeded()
    }
}
