import Foundation

enum TransactionBalanceService {
    static func recalculateBalances(for book: BookEntity) {
        var runningBalance = 0.0
        for entry in book.transactionArray {
            runningBalance += entry.signedAmount
            entry.runningBalance = runningBalance
        }
        book.updatedAt = Date()
    }
}
