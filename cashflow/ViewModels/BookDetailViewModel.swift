import Combine
import CoreData
import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
    @Published var filter = TransactionFilterState()
    @Published var errorMessage: String?

    let book: BookEntity
    private weak var context: NSManagedObjectContext?

    init(book: BookEntity) {
        self.book = book
    }

    func configure(context: NSManagedObjectContext) {
        self.context = context
        FinanceCatalogService.seedDefaultsIfNeeded(for: book, in: context)
        try? context.saveIfNeeded()
    }

    var allTransactions: [TransactionEntry] {
        book.transactionArray
    }

    var filteredTransactions: [TransactionEntry] {
        let calendar = Calendar.current
        return allTransactions
            .filter { entry in
                switch filter.datePreset {
                case .all:
                    true
                case .today:
                    calendar.isDateInToday(entry.occurredAt ?? .distantPast)
                case .last7Days:
                    (entry.occurredAt ?? .distantPast) >= (calendar.date(byAdding: .day, value: -7, to: .now) ?? .distantPast)
                case .thisMonth:
                    calendar.isDate(entry.occurredAt ?? .distantPast, equalTo: .now, toGranularity: .month)
                }
            }
            .filter { entry in
                filter.kind == nil || entry.transactionKind == filter.kind
            }
            .filter { entry in
                filter.categoryName == "All" || entry.category?.wrappedName == filter.categoryName
            }
            .filter { entry in
                filter.paymentModeName == "All" || entry.paymentMode?.wrappedName == filter.paymentModeName
            }
            .sorted {
                if $0.occurredAt == $1.occurredAt {
                    return ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
                }
                return ($0.occurredAt ?? .distantPast) > ($1.occurredAt ?? .distantPast)
            }
    }

    var groupedTransactions: [(date: Date, entries: [TransactionEntry])] {
        let groups = Dictionary(grouping: filteredTransactions) { Calendar.current.startOfDay(for: $0.occurredAt ?? .distantPast) }
        return groups.keys.sorted(by: >).map { date in
            (date, groups[date] ?? [])
        }
    }

    var totalCashIn: Double {
        filteredTransactions.filter { $0.transactionKind == .cashIn }.reduce(0) { $0 + $1.amount }
    }

    var totalCashOut: Double {
        filteredTransactions.filter { $0.transactionKind == .cashOut }.reduce(0) { $0 + $1.amount }
    }

    var netBalance: Double {
        totalCashIn - totalCashOut
    }

    var categoryOptions: [String] {
        ["All"] + book.categoriesArray.map(\.wrappedName)
    }

    var paymentModeOptions: [String] {
        ["All"] + book.paymentModesArray.map(\.wrappedName)
    }

    func saveTransaction(draft: TransactionDraft, editing transaction: TransactionEntry?) -> Bool {
        guard let context else { return false }
        guard let amount = draft.amountValue, amount > 0 else {
            errorMessage = "Enter a valid amount greater than zero."
            return false
        }

        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedTitle.isEmpty == false else {
            errorMessage = "Transaction title is required."
            return false
        }

        let entry = transaction ?? TransactionEntry(context: context)
        let previousSnapshot = transaction.map(makeSnapshot)
        let now = Date()

        if transaction == nil {
            entry.id = UUID()
            entry.createdAt = now
            entry.book = book
        }

        entry.title = trimmedTitle
        entry.amount = amount
        entry.transactionKind = draft.type
        entry.occurredAt = draft.occurredAt
        entry.updatedAt = now
        entry.editorName = book.ownerName
        entry.notes = draft.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.category = FinanceCatalogService.findOrCreateCategory(named: draft.categoryName, for: book, in: context)
        entry.paymentMode = FinanceCatalogService.findOrCreatePaymentMode(named: draft.paymentModeName, for: book, in: context)

        createLog(for: entry, previousSnapshot: previousSnapshot, in: context)
        TransactionBalanceService.recalculateBalances(for: book)

        do {
            try context.saveIfNeeded()
            return true
        } catch {
            context.rollback()
            errorMessage = "Unable to save the transaction."
            return false
        }
    }

    func deleteTransaction(_ transaction: TransactionEntry) {
        guard let context else { return }
        context.delete(transaction)
        TransactionBalanceService.recalculateBalances(for: book)

        do {
            try context.saveIfNeeded()
        } catch {
            context.rollback()
            errorMessage = "Unable to delete the transaction."
        }
    }

    func reportSnapshot(for type: ReportType) -> ReportSnapshot {
        switch type {
        case .allEntries:
            return ReportSnapshot(
                type: type,
                rows: filteredTransactions.map {
                    ReportRow(
                        title: $0.title ?? "Untitled Entry",
                        subtitle: "\($0.editorName ?? "You") • \($0.category?.wrappedName ?? "-") • \($0.paymentMode?.wrappedName ?? "-") • \(AppFormatters.bookDate.string(from: $0.occurredAt ?? .now))",
                        amount: $0.signedAmount,
                        balance: $0.runningBalance
                    )
                },
                totalCashIn: totalCashIn,
                totalCashOut: totalCashOut,
                netBalance: netBalance
            )
        case .dayWise:
            let grouped = Dictionary(grouping: filteredTransactions) { Calendar.current.startOfDay(for: $0.occurredAt ?? .distantPast) }
            let rows = grouped.keys.sorted(by: >).map { date in
                let dayEntries = grouped[date] ?? []
                let amount = dayEntries.reduce(0) { $0 + $1.signedAmount }
                return ReportRow(
                    title: AppFormatters.sectionDate.string(from: date),
                    subtitle: "\(dayEntries.count) entries",
                    amount: amount,
                    balance: nil
                )
            }
            return ReportSnapshot(type: type, rows: rows, totalCashIn: totalCashIn, totalCashOut: totalCashOut, netBalance: netBalance)
        case .categoryWise:
            let grouped = Dictionary(grouping: filteredTransactions) { $0.category?.wrappedName ?? "Uncategorized" }
            let rows = grouped.keys.sorted().map { key in
                let entries = grouped[key] ?? []
                return ReportRow(title: key, subtitle: "\(entries.count) entries", amount: entries.reduce(0) { $0 + $1.signedAmount }, balance: nil)
            }
            return ReportSnapshot(type: type, rows: rows, totalCashIn: totalCashIn, totalCashOut: totalCashOut, netBalance: netBalance)
        case .paymentMode:
            let grouped = Dictionary(grouping: filteredTransactions) { $0.paymentMode?.wrappedName ?? "Unknown" }
            let rows = grouped.keys.sorted().map { key in
                let entries = grouped[key] ?? []
                return ReportRow(title: key, subtitle: "\(entries.count) entries", amount: entries.reduce(0) { $0 + $1.signedAmount }, balance: nil)
            }
            return ReportSnapshot(type: type, rows: rows, totalCashIn: totalCashIn, totalCashOut: totalCashOut, netBalance: netBalance)
        }
    }

    private func makeSnapshot(_ transaction: TransactionEntry) -> [String: String] {
        [
            "Title": transaction.title ?? "Untitled Entry",
            "Amount": AppFormatters.currencyString(for: transaction.amount),
            "Type": transaction.transactionKind.title,
            "Category": transaction.category?.wrappedName ?? "-",
            "Payment Mode": transaction.paymentMode?.wrappedName ?? "-",
            "Date": AppFormatters.bookDate.string(from: transaction.occurredAt ?? .now),
            "Notes": transaction.notes ?? ""
        ]
    }

    private func createLog(for transaction: TransactionEntry, previousSnapshot: [String: String]?, in context: NSManagedObjectContext) {
        let log = TransactionLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.transaction = transaction

        if let previousSnapshot {
            let currentSnapshot = makeSnapshot(transaction)
            let changes = currentSnapshot.compactMap { key, value -> String? in
                guard previousSnapshot[key] != value else { return nil }
                return "\(key): \(previousSnapshot[key] ?? "-") → \(value)"
            }

            log.action = "Edited"
            log.details = changes.isEmpty ? "Transaction updated with no field-level changes detected." : changes.joined(separator: "\n")
        } else {
            log.action = "Created"
            log.details = "Transaction created by \(book.ownerName ?? "You")"
        }
    }
}
