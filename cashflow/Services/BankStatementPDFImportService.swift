import Foundation
import PDFKit

enum BankStatementPDFImportService {
    static func parseStatement(from url: URL) throws -> StatementImportPreview {
        guard let document = PDFDocument(url: url) else {
            throw PDFImportError.invalidPDF
        }

        let text = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }
            .joined(separator: "\n")

        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\t", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }

        let candidateBlocks = buildTransactionBlocks(from: lines)
        var parsedTransactions: [ImportedStatementTransaction] = []
        var ignoredLineCount = 0

        for block in candidateBlocks {
            if let transaction = parseTransactionLine(block) {
                parsedTransactions.append(transaction)
            } else {
                ignoredLineCount += 1
            }
        }

        return StatementImportPreview(sourceURL: url, transactions: parsedTransactions, ignoredLineCount: ignoredLineCount)
    }

    static func parseTransactionLine(_ line: String) -> ImportedStatementTransaction? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let match = statementLineRegex.firstMatch(in: trimmedLine, range: NSRange(trimmedLine.startIndex..., in: trimmedLine)),
              let dateRange = Range(match.range(at: 1), in: trimmedLine),
              let descriptionRange = Range(match.range(at: 3), in: trimmedLine),
              let withdrawRange = Range(match.range(at: 4), in: trimmedLine),
              let depositRange = Range(match.range(at: 5), in: trimmedLine),
              let balanceRange = Range(match.range(at: 6), in: trimmedLine) else {
            return nil
        }

        let dateString = String(trimmedLine[dateRange])
        guard let occurredAt = parseDate(dateString) else { return nil }

        let description = String(trimmedLine[descriptionRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard description.isEmpty == false else { return nil }
        guard description.caseInsensitiveCompare("Opening Balance") != .orderedSame,
              description.caseInsensitiveCompare("Closing Balance") != .orderedSame else {
            return nil
        }

        let withdrawRaw = String(trimmedLine[withdrawRange])
        let depositRaw = String(trimmedLine[depositRange])
        let balanceRaw = String(trimmedLine[balanceRange])

        guard let withdrawAmount = parseAmountOrDash(withdrawRaw),
              let depositAmount = parseAmountOrDash(depositRaw),
              let balance = parseAmount(balanceRaw) else {
            return nil
        }

        guard withdrawAmount > 0 || depositAmount > 0 else { return nil }

        return ImportedStatementTransaction(
            occurredAt: occurredAt,
            description: description,
            withdrawAmount: withdrawAmount,
            depositAmount: depositAmount,
            balance: balance
        )
    }

    private static func buildTransactionBlocks(from lines: [String]) -> [String] {
        var blocks: [String] = []
        var currentBlock: String?

        for line in lines {
            if shouldIgnoreNonTransactionLine(line) {
                continue
            }

            if transactionStartRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                if let currentBlock {
                    blocks.append(currentBlock)
                }
                currentBlock = line
            } else if let existingBlock = currentBlock {
                currentBlock = existingBlock + " " + line
            }
        }

        if let currentBlock {
            blocks.append(currentBlock)
        }

        return blocks
            .map {
                $0.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .filter { $0.isEmpty == false }
    }

    private static func parseAmount(_ value: String) -> Double? {
        let cleaned = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "CR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "DR", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned)
    }

    private static func parseAmountOrDash(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "-" {
            return 0
        }
        return parseAmount(trimmed)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatters: [DateFormatter] = [
            formatter("yyyy-MM-dd"),
            formatter("dd/MM/yyyy"),
            formatter("d/M/yyyy"),
            formatter("dd-MM-yyyy"),
            formatter("d-M-yyyy"),
            formatter("dd/MM/yy"),
            formatter("dd-MM-yy"),
            formatter("dd MMM yyyy"),
            formatter("d MMM yyyy"),
            formatter("dd MMM yy")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    private static func formatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = format
        return formatter
    }

    private static let statementLineRegex = try! NSRegularExpression(
        pattern: #"^\s*(\d{4}-\d{2}-\d{2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4})(?:\s+(\d{2}:\d{2}:?(?::\d{2})?))?\s+(.*?)\s+(-|\d[\d,]*(?:\.\d{1,2})?(?:\s?(?:CR|DR))?)\s+(-|\d[\d,]*(?:\.\d{1,2})?(?:\s?(?:CR|DR))?)\s+(\d[\d,]*(?:\.\d{1,2})?(?:\s?(?:CR|DR))?)\s*$"#,
        options: [.caseInsensitive]
    )

    private static let transactionStartRegex = try! NSRegularExpression(
        pattern: #"^\s*(\d{4}-\d{2}-\d{2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4})\b"#,
        options: []
    )

    private static func shouldIgnoreNonTransactionLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()

        if lowercased.hasPrefix("electronic account statement") ||
            lowercased.hasPrefix("account holder") ||
            lowercased.hasPrefix("account name:") ||
            lowercased.hasPrefix("account number") ||
            lowercased.hasPrefix("interest rate") ||
            lowercased.hasPrefix("currency code") ||
            lowercased.hasPrefix("from:") ||
            lowercased.hasPrefix("to date") ||
            lowercased.hasPrefix("from date") ||
            lowercased.hasPrefix("opening balance") ||
            lowercased.hasPrefix("closing balance") ||
            lowercased.hasPrefix("accrued interest") ||
            lowercased.hasPrefix("transaction date description") ||
            lowercased.hasPrefix("s.n cheque number") ||
            lowercased.hasPrefix("report generated on:") ||
            lowercased.hasPrefix("the statement reflects account transaction") ||
            lowercased.hasPrefix("intended to be utilized") ||
            lowercased.hasPrefix("branch.") {
            return true
        }

        if line.range(of: #"^\d+$"#, options: .regularExpression) != nil {
            return true
        }

        return false
    }
}

enum PDFImportError: LocalizedError {
    case invalidPDF
    case noTransactionsFound

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            "The selected file could not be read as a PDF."
        case .noTransactionsFound:
            "No valid transactions were found in the selected PDF."
        }
    }
}
