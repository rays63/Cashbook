import CoreData
import Foundation

extension BookEntity {
    var categoriesArray: [CategoryEntity] {
        ((categories as? Set<CategoryEntity>) ?? []).sorted { $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending }
    }

    var paymentModesArray: [PaymentModeEntity] {
        ((paymentModes as? Set<PaymentModeEntity>) ?? []).sorted { $0.wrappedName.localizedCaseInsensitiveCompare($1.wrappedName) == .orderedAscending }
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
