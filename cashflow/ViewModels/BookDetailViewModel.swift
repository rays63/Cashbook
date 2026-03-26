import Combine
import CoreData
import Foundation

@MainActor
final class BookDetailViewModel: ObservableObject {
    @Published var filter = TransactionFilterState()
    @Published var errorMessage: String?
    @Published var importPreview: StatementImportPreview?

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

    var goalOptions: [String] {
        guard let context else { return [] }
        let request = GoalEntity.fetchRequest()
        let goals = (try? context.fetch(request)) ?? []
        return goals
            .sorted { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
            .map(\.wrappedName)
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
        if draft.type == .cashIn {
            let request = GoalEntity.fetchRequest()
            let goals = (try? context.fetch(request)) ?? []
            entry.goal = goals.first(where: { $0.wrappedName == draft.goalName })
        } else {
            entry.goal = nil
        }

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

    func preparePDFImport(from url: URL) {
        do {
            let preview = try BankStatementPDFImportService.parseStatement(from: url)
            let deduplicatedPreview = removeDuplicateImports(from: preview)
            guard deduplicatedPreview.transactions.isEmpty == false else {
                errorMessage = preview.transactions.isEmpty
                    ? PDFImportError.noTransactionsFound.localizedDescription
                    : PDFImportError.allTransactionsDuplicate.localizedDescription
                return
            }
            importPreview = deduplicatedPreview
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func prepareXLSImport(from url: URL) {
        do {
            let preview = try LegacyXLSStatementImportService.parseStatement(from: url)
            let deduplicatedPreview = removeDuplicateImports(from: preview)
            guard deduplicatedPreview.transactions.isEmpty == false else {
                errorMessage = preview.transactions.isEmpty
                    ? PDFImportError.noTransactionsFound.localizedDescription
                    : PDFImportError.allTransactionsDuplicate.localizedDescription
                return
            }
            importPreview = deduplicatedPreview
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func commitImportPreview() -> Bool {
        guard let context, let importPreview else { return false }

        let importedCategory = FinanceCatalogService.findOrCreateCategory(named: "Bank Statement", for: book, in: context)
        let importedPaymentMode = FinanceCatalogService.findOrCreatePaymentMode(named: "Bank", for: book, in: context)
        let now = Date()
        let existingTitleCounts = Dictionary(grouping: book.transactionArray.map { normalizedImportTitle($0.title ?? "") }, by: { $0 })
            .mapValues(\.count)
        let incomingTitleCounts = Dictionary(grouping: importPreview.transactions.map { normalizedImportTitle($0.description) }, by: { $0 })
            .mapValues(\.count)

        for item in importPreview.transactions {
            let entry = TransactionEntry(context: context)
            entry.id = UUID()
            entry.createdAt = now
            entry.updatedAt = now
            entry.book = book
            let normalizedDescription = normalizedImportTitle(item.description)
            let normalizedReference = normalizedImportTitle(item.externalReference ?? "")
            let hasLiteralDescription = normalizedDescription.isEmpty == false && normalizedDescription != normalizedReference
            let needsReferenceSuffix =
                item.externalReference?.isEmpty == false &&
                (incomingTitleCounts[normalizedDescription, default: 0] > 1 ||
                 existingTitleCounts[normalizedDescription, default: 0] > 0)

            if hasLiteralDescription {
                if let externalReference = item.externalReference, needsReferenceSuffix {
                    entry.title = "\(item.description) - \(externalReference)"
                } else {
                    entry.title = item.description
                }
            } else if let externalReference = item.externalReference, externalReference.isEmpty == false {
                entry.title = "Statement Entry - \(externalReference)"
            } else {
                entry.title = "Statement Entry"
            }
            entry.amount = item.transactionAmount
            entry.transactionKind = item.transactionKind
            entry.occurredAt = item.occurredAt
            entry.editorName = book.ownerName
            var notes = "Imported from \(importPreview.sourceURL.lastPathComponent)\nStatement Balance: \(AppFormatters.currencyString(for: item.balance))"
            if let externalReference = item.externalReference, externalReference.isEmpty == false {
                notes += "\nReference Code: \(externalReference)"
            }
            entry.notes = notes
            entry.category = importedCategory
            entry.paymentMode = importedPaymentMode
            createImportLog(for: entry, in: context)
        }

        TransactionBalanceService.recalculateBalances(for: book)

        do {
            try context.saveIfNeeded()
            self.importPreview = nil
            return true
        } catch {
            context.rollback()
            errorMessage = "Unable to import transactions from the selected statement."
            return false
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
            "Goal": transaction.goal?.wrappedName ?? "-",
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

    private func createImportLog(for transaction: TransactionEntry, in context: NSManagedObjectContext) {
        let log = TransactionLog(context: context)
        log.id = UUID()
        log.timestamp = Date()
        log.transaction = transaction
        log.action = "Imported"
        log.details = "Transaction imported from statement file."
    }

    private func removeDuplicateImports(from preview: StatementImportPreview) -> StatementImportPreview {
        let existingSignatures = Set(book.transactionArray.map(transactionSignature(for:)))
        var seenImportSignatures = Set<String>()
        var uniqueTransactions: [ImportedStatementTransaction] = []
        var duplicateCount = 0

        for item in preview.transactions {
            let signature = importSignature(for: item)
            if existingSignatures.contains(signature) || seenImportSignatures.contains(signature) {
                duplicateCount += 1
                continue
            }

            seenImportSignatures.insert(signature)
            uniqueTransactions.append(item)
        }

        return StatementImportPreview(
            sourceURL: preview.sourceURL,
            transactions: uniqueTransactions,
            ignoredLineCount: preview.ignoredLineCount,
            duplicateLineCount: duplicateCount
        )
    }

    private func transactionSignature(for transaction: TransactionEntry) -> String {
        let date = normalizedImportDate(transaction.occurredAt ?? .distantPast)
        let externalReference = importedReferenceCode(for: transaction) ?? "no-reference"
        let title = normalizedStoredImportTitle(transaction.title ?? "", externalReference: importedReferenceCode(for: transaction))
        let balance = importedStatementBalance(for: transaction)
        return "\(date)|\(transaction.transactionKind.rawValue)|\(normalizedAmount(transaction.amount))|\(title)|\(balance.map(normalizedAmount) ?? "no-balance")|\(externalReference)"
    }

    private func importSignature(for transaction: ImportedStatementTransaction) -> String {
        let date = normalizedImportDate(transaction.occurredAt)
        let title = normalizedImportTitle(transaction.description)
        let externalReference = transaction.externalReference ?? "no-reference"
        return "\(date)|\(transaction.transactionKind.rawValue)|\(normalizedAmount(transaction.transactionAmount))|\(title)|\(normalizedAmount(transaction.balance))|\(externalReference)"
    }

    private func normalizedImportDate(_ date: Date) -> String {
        let startOfDay = Calendar.current.startOfDay(for: date)
        return ISO8601DateFormatter().string(from: startOfDay)
    }

    private func normalizedImportTitle(_ title: String) -> String {
        title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .lowercased()
    }

    private func normalizedStoredImportTitle(_ title: String, externalReference: String?) -> String {
        var normalizedTitle = normalizedImportTitle(title)
        guard let externalReference else { return normalizedTitle }

        let normalizedReference = normalizedImportTitle(externalReference)
        let suffix = " - \(normalizedReference)"
        if normalizedTitle.hasSuffix(suffix) {
            normalizedTitle.removeLast(suffix.count)
        }

        return normalizedTitle
    }

    private func normalizedAmount(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func importedStatementBalance(for transaction: TransactionEntry) -> Double? {
        guard let notes = transaction.notes else { return nil }
        guard let range = notes.range(of: "Statement Balance:", options: .caseInsensitive) else { return nil }

        let rawValue = notes[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""

        let cleaned = rawValue
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: AppFormatters.currency.currencySymbol ?? "", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned)
    }

    private func importedReferenceCode(for transaction: TransactionEntry) -> String? {
        guard let notes = transaction.notes else { return nil }
        guard let range = notes.range(of: "Reference Code:", options: .caseInsensitive) else { return nil }
        let rawValue = notes[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        return rawValue.isEmpty ? nil : rawValue
    }
}
