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
            let entries = orderedEntriesForDisplay(groups[date] ?? [])
            return (date, entries)
        }
    }

    var totalCashIn: Double {
        filteredTransactions.filter { $0.transactionKind == .cashIn }.reduce(0) { $0 + $1.amount }
    }

    var totalCashOut: Double {
        filteredTransactions.filter { $0.transactionKind == .cashOut }.reduce(0) { $0 + $1.amount }
    }

    var netBalance: Double {
        groupedTransactions.first?.entries.first?.runningBalance ?? book.balance
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
            if preview.transactions.isEmpty {
                errorMessage = PDFImportError.noTransactionsFound.localizedDescription
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
            if preview.transactions.isEmpty {
                errorMessage = PDFImportError.noTransactionsFound.localizedDescription
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
        let fallbackSortedImportItems = importPreview.transactions
            .sorted { lhs, rhs in
                if lhs.occurredAt == rhs.occurredAt {
                    return lhs.sequence < rhs.sequence
                }
                return lhs.occurredAt < rhs.occurredAt
            }
        let sortedImportItems = orderedImportedTransactionsForCalculation(
            fallbackSortedImportItems,
            openingBalance: importPreview.openingBalance
        )
        let existingTitleCounts = Dictionary(grouping: book.transactionArray.map { normalizedImportTitle($0.title ?? "") }, by: { $0 })
            .mapValues(\.count)
        let incomingTitleCounts = Dictionary(grouping: sortedImportItems.map { normalizedImportTitle($0.description) }, by: { $0 })
            .mapValues(\.count)

        if book.transactionArray.isEmpty,
           let openingBalance = importPreview.openingBalance,
           abs(openingBalance) > 0.0001 {
            let openingEntry = TransactionEntry(context: context)
            openingEntry.id = UUID()
            openingEntry.createdAt = now.addingTimeInterval(-1)
            openingEntry.updatedAt = now.addingTimeInterval(-1)
            openingEntry.book = book
            openingEntry.title = "Opening Balance"
            openingEntry.amount = abs(openingBalance)
            openingEntry.transactionKind = openingBalance >= 0 ? .cashIn : .cashOut
            openingEntry.occurredAt = (sortedImportItems.first?.occurredAt ?? .now).addingTimeInterval(-1)
            openingEntry.editorName = book.ownerName
            openingEntry.notes = "Imported opening balance from \(importPreview.sourceURL.lastPathComponent)"
            openingEntry.category = importedCategory
            openingEntry.paymentMode = importedPaymentMode
            createImportLog(for: openingEntry, in: context)
        }

        for (index, item) in sortedImportItems.enumerated() {
            let entry = TransactionEntry(context: context)
            entry.id = UUID()
            entry.createdAt = now.addingTimeInterval(TimeInterval(index))
            entry.updatedAt = now.addingTimeInterval(TimeInterval(index))
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
            var notes = "Imported from \(importPreview.sourceURL.lastPathComponent)\nStatement Sequence: \(item.sequence)\nStatement Balance: \(AppFormatters.currencyString(for: item.balance))"
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
                        balance: $0.displayBalance
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

    private func orderedEntriesForDisplay(_ entries: [TransactionEntry]) -> [TransactionEntry] {
        let fallback = entries.sorted {
            if $0.occurredAt == $1.occurredAt {
                if $0.createdAt == $1.createdAt {
                    return $0.objectID.uriRepresentation().absoluteString > $1.objectID.uriRepresentation().absoluteString
                }
                return ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
            return ($0.occurredAt ?? .distantPast) > ($1.occurredAt ?? .distantPast)
        }

        let importedEntries = entries.filter { $0.importedStatementBalance != nil }
        guard importedEntries.count >= 2 else { return fallback }

        if let inferredOrder = inferStatementSequence(entries) {
            return inferredOrder
        }

        return fallback
    }

    private func inferStatementSequence(_ entries: [TransactionEntry]) -> [TransactionEntry]? {
        let importedEntries = entries.filter { $0.importedStatementBalance != nil }
        guard importedEntries.count >= 2 else { return nil }

        let ids = importedEntries.map { $0.objectID.uriRepresentation().absoluteString }
        var predecessorByID: [String: String] = [:]
        var successorByID: [String: String] = [:]

        for candidate in importedEntries {
            let candidateID = candidate.objectID.uriRepresentation().absoluteString
            let candidatePreviousBalance = candidate.displayBalance - candidate.signedAmount

            let matches = importedEntries.filter { other in
                let otherID = other.objectID.uriRepresentation().absoluteString
                guard otherID != candidateID else { return false }
                return amountsApproximatelyEqual(other.displayBalance, candidatePreviousBalance)
            }

            guard matches.count == 1 else { continue }

            let predecessor = matches[0]
            let predecessorID = predecessor.objectID.uriRepresentation().absoluteString
            predecessorByID[candidateID] = predecessorID
            successorByID[predecessorID] = candidateID
        }

        let entryByID = Dictionary(uniqueKeysWithValues: importedEntries.map { ($0.objectID.uriRepresentation().absoluteString, $0) })
        let chainStarts = ids.filter { predecessorByID[$0] == nil }
        guard chainStarts.isEmpty == false else { return nil }

        var orderedAscending: [TransactionEntry] = []
        var visited = Set<String>()

        for startID in chainStarts {
            var currentID: String? = startID
            while let unwrappedID = currentID, visited.contains(unwrappedID) == false {
                visited.insert(unwrappedID)
                if let entry = entryByID[unwrappedID] {
                    orderedAscending.append(entry)
                }
                currentID = successorByID[unwrappedID]
            }
        }

        let remaining = importedEntries.filter { visited.contains($0.objectID.uriRepresentation().absoluteString) == false }
        let fallbackRemaining = remaining.sorted {
            if $0.createdAt == $1.createdAt {
                return $0.objectID.uriRepresentation().absoluteString < $1.objectID.uriRepresentation().absoluteString
            }
            return ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast)
        }
        orderedAscending.append(contentsOf: fallbackRemaining)

        guard orderedAscending.isEmpty == false else { return nil }

        let orderedDescendingImported = Array(orderedAscending.reversed())
        let nonImported = entries.filter { $0.importedStatementBalance == nil }.sorted {
            if $0.occurredAt == $1.occurredAt {
                if $0.createdAt == $1.createdAt {
                    return $0.objectID.uriRepresentation().absoluteString > $1.objectID.uriRepresentation().absoluteString
                }
                return ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            }
            return ($0.occurredAt ?? .distantPast) > ($1.occurredAt ?? .distantPast)
        }

        return orderedDescendingImported + nonImported
    }

    private func amountsApproximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.01
    }

    private func removeDuplicateImports(from preview: StatementImportPreview) -> StatementImportPreview {
        let existingSignatures = Set(book.transactionArray.map(transactionSignature(for:)))
        var seenImportSignatures = Set<String>()
        var uniqueTransactions: [ImportedStatementTransaction] = []
        var duplicateTransactions: [ImportedStatementTransaction] = []
        var duplicateCount = 0

        for item in preview.transactions {
            let signature = importSignature(for: item)
            if existingSignatures.contains(signature) || seenImportSignatures.contains(signature) {
                duplicateCount += 1
                duplicateTransactions.append(item)
                continue
            }

            seenImportSignatures.insert(signature)
            uniqueTransactions.append(item)
        }

        return StatementImportPreview(
            sourceURL: preview.sourceURL,
            transactions: uniqueTransactions,
            ignoredLineCount: preview.ignoredLineCount,
            duplicateLineCount: duplicateCount,
            duplicateTransactions: duplicateTransactions,
            openingBalance: preview.openingBalance,
            closingBalance: preview.closingBalance
        )
    }

    private func orderedImportedTransactionsForCalculation(
        _ items: [ImportedStatementTransaction],
        openingBalance: Double?
    ) -> [ImportedStatementTransaction] {
        guard items.count >= 2 else { return items }

        let indexedItems = Array(items.enumerated())
        let idByIndex = Dictionary(uniqueKeysWithValues: indexedItems.map { ($0.offset, "item-\($0.offset)") })
        let itemByID = Dictionary(uniqueKeysWithValues: indexedItems.map { ("item-\($0.offset)", $0.element) })

        var predecessorByID: [String: String] = [:]
        var successorByID: [String: String] = [:]
        var openingStarts = Set<String>()

        for (index, item) in indexedItems {
            let itemID = idByIndex[index] ?? "item-\(index)"
            let expectedPreviousBalance = item.balance - item.transactionKind.amountPrefixValue * item.transactionAmount

            if let openingBalance, amountsApproximatelyEqual(openingBalance, expectedPreviousBalance) {
                openingStarts.insert(itemID)
            }

            let matches = indexedItems.filter { otherIndex, otherItem in
                guard otherIndex != index else { return false }
                return amountsApproximatelyEqual(otherItem.balance, expectedPreviousBalance)
            }

            guard matches.count == 1 else { continue }

            let predecessorID = idByIndex[matches[0].offset] ?? "item-\(matches[0].offset)"
            predecessorByID[itemID] = predecessorID
            successorByID[predecessorID] = itemID
        }

        let allIDs = indexedItems.map { idByIndex[$0.offset] ?? "item-\($0.offset)" }
        let startIDs = allIDs.filter { predecessorByID[$0] == nil }
        let preferredStarts = startIDs.sorted { lhs, rhs in
            let lhsOpening = openingStarts.contains(lhs)
            let rhsOpening = openingStarts.contains(rhs)
            if lhsOpening != rhsOpening {
                return lhsOpening && !rhsOpening
            }

            guard let lhsItem = itemByID[lhs], let rhsItem = itemByID[rhs] else { return lhs < rhs }
            if lhsItem.occurredAt == rhsItem.occurredAt {
                return lhsItem.sequence < rhsItem.sequence
            }
            return lhsItem.occurredAt < rhsItem.occurredAt
        }

        var ordered: [ImportedStatementTransaction] = []
        var visited = Set<String>()

        for startID in preferredStarts {
            var currentID: String? = startID
            while let unwrappedID = currentID, visited.contains(unwrappedID) == false {
                visited.insert(unwrappedID)
                if let item = itemByID[unwrappedID] {
                    ordered.append(item)
                }
                currentID = successorByID[unwrappedID]
            }
        }

        let remaining = allIDs.filter { visited.contains($0) == false }.compactMap { itemByID[$0] }
        let fallbackRemaining = remaining.sorted {
            if $0.occurredAt == $1.occurredAt {
                return $0.sequence < $1.sequence
            }
            return $0.occurredAt < $1.occurredAt
        }
        ordered.append(contentsOf: fallbackRemaining)

        return ordered
    }

    private func transactionSignature(for transaction: TransactionEntry) -> String {
        let date = normalizedImportDate(transaction.occurredAt ?? .distantPast)
        let externalReference = importedReferenceCode(for: transaction) ?? "no-reference"
        let title = normalizedStoredImportTitle(transaction.title ?? "", externalReference: importedReferenceCode(for: transaction))
        let balance = importedStatementBalance(for: transaction)
        let sequence = importedStatementSequence(for: transaction).map(String.init) ?? "no-sequence"
        return "\(date)|\(transaction.transactionKind.rawValue)|\(normalizedAmount(transaction.amount))|\(title)|\(balance.map(normalizedAmount) ?? "no-balance")|\(externalReference)|\(sequence)"
    }

    private func importSignature(for transaction: ImportedStatementTransaction) -> String {
        let date = normalizedImportDate(transaction.occurredAt)
        let title = normalizedImportTitle(transaction.description)
        let externalReference = transaction.externalReference ?? "no-reference"
        return "\(date)|\(transaction.transactionKind.rawValue)|\(normalizedAmount(transaction.transactionAmount))|\(title)|\(normalizedAmount(transaction.balance))|\(externalReference)|\(transaction.sequence)"
    }

    private func normalizedImportDate(_ date: Date) -> String {
        return importDateFormatter.string(from: date)
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

    private func importedStatementSequence(for transaction: TransactionEntry) -> Int? {
        guard let notes = transaction.notes else { return nil }
        guard let range = notes.range(of: "Statement Sequence:", options: .caseInsensitive) else { return nil }
        let rawValue = notes[range.upperBound...]
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first ?? ""
        return Int(rawValue)
    }

    private var importDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = .current
        return formatter
    }
}

private extension TransactionKind {
    var amountPrefixValue: Double {
        switch self {
        case .cashIn:
            return 1
        case .cashOut:
            return -1
        }
    }
}
