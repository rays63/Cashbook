import CoreData
import Foundation

enum TransactionBalanceService {
    static func recalculateBalances(for book: BookEntity) {
        var runningBalance = 0.0
        let entries = ((book.transactions as? Set<TransactionEntry>) ?? []).sorted {
            if $0.occurredAt == $1.occurredAt {
                if $0.createdAt == $1.createdAt {
                    return $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString
                }
                return ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
            }
            return ($0.occurredAt ?? .distantPast) < ($1.occurredAt ?? .distantPast)
        }

        for entry in entries {
            runningBalance += entry.signedAmount
            entry.runningBalance = runningBalance
        }
        book.updatedAt = Date()
    }
}
