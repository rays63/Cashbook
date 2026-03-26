import CoreData
import Foundation

extension BookEntity {
    var categoriesArray: [CategoryEntity] {
        ((categories as? Set<CategoryEntity>) ?? []).sorted { $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending }
    }

    var paymentModesArray: [PaymentModeEntity] {
        ((paymentModes as? Set<PaymentModeEntity>) ?? []).sorted { $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending }
    }

    var goalsArray: [GoalEntity] {
        ((goals as? Set<GoalEntity>) ?? []).sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
    }

    var transactionArray: [TransactionEntry] {
        ((transactions as? Set<TransactionEntry>) ?? []).sorted {
            if $0.occurredAt == $1.occurredAt {
                return ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
            }
            return ($0.occurredAt ?? .distantPast) < ($1.occurredAt ?? .distantPast)
        }
    }

    var balance: Double {
        transactionArray.last?.runningBalance ?? 0
    }
}

extension CategoryEntity {
    var wrappedName: String { name ?? "Untitled" }
}

extension PaymentModeEntity {
    var wrappedName: String { name ?? "Unknown" }
}

extension GoalEntity {
    var wrappedName: String { name ?? "Untitled Goal" }

    var transactionsArray: [TransactionEntry] {
        ((transactions as? Set<TransactionEntry>) ?? []).sorted { ($0.occurredAt ?? .distantPast) > ($1.occurredAt ?? .distantPast) }
    }

    var currentProgress: Double {
        transactionsArray
            .filter { $0.transactionKind == .cashIn }
            .reduce(0) { $0 + $1.amount }
    }

    var progressRatio: Double {
        guard targetAmount > 0 else { return 0 }
        return min(currentProgress / targetAmount, 1)
    }
}

extension TransactionEntry {
    var logArray: [TransactionLog] {
        ((logs as? Set<TransactionLog>) ?? []).sorted { ($0.timestamp ?? .distantPast) > ($1.timestamp ?? .distantPast) }
    }

    var transactionKind: TransactionKind {
        get { TransactionKind(rawValue: typeRaw) ?? .cashIn }
        set { typeRaw = newValue.rawValue }
    }

    var signedAmount: Double {
        transactionKind == .cashIn ? amount : -amount
    }
}

extension TransactionLog {
}
