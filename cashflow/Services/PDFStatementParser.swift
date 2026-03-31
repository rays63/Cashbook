import Foundation
import PDFKit

struct PDFStatementParserResult {
    let transactions: [ImportedStatementTransaction]
    let ignoredLineCount: Int
    let openingBalance: Double?
    let closingBalance: Double?
}

enum PDFStatementParser {
    static func parse(document: PDFDocument) -> PDFStatementParserResult {
        let pageTexts = (0..<document.pageCount)
            .compactMap { document.page(at: $0)?.string }

        let allLines = pageTexts.flatMap { normalizedLines(from: $0) }
        let openingBalance = extractBalance(labels: ["opening balance", "balance from previous statement"], from: allLines)
        let closingBalance = extractBalance(label: "closing balance", from: allLines)
        let candidateBlocks = pageTexts.flatMap { buildTransactionBlocks(from: normalizedLines(from: $0)) }

        var parsedTransactions: [ImportedStatementTransaction] = []
        var ignoredLineCount = 0
        var previousBalance = openingBalance

        for (index, block) in candidateBlocks.enumerated() {
            if let transaction = parseTransactionLine(block, previousBalance: previousBalance) {
                parsedTransactions.append(
                    ImportedStatementTransaction(
                        sequence: index,
                        occurredAt: transaction.occurredAt,
                        description: transaction.description,
                        withdrawAmount: transaction.withdrawAmount,
                        depositAmount: transaction.depositAmount,
                        balance: transaction.balance,
                        externalReference: transaction.externalReference
                    )
                )
                previousBalance = transaction.balance
            } else {
                ignoredLineCount += 1
            }
        }

        return PDFStatementParserResult(
            transactions: parsedTransactions,
            ignoredLineCount: ignoredLineCount,
            openingBalance: openingBalance,
            closingBalance: closingBalance
        )
    }

    static func normalizedLines(from text: String) -> [String] {
        text
            .components(separatedBy: .newlines)
            .map { $0.replacingOccurrences(of: "\t", with: " ").trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.isEmpty == false }
    }

    static func parseTransactionLine(_ line: String, previousBalance: Double? = nil) -> ImportedStatementTransaction? {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedComponents: (dateString: String, timeString: String?, description: String, withdrawRaw: String, depositRaw: String, balanceRaw: String)?

        if let match = statementLineRegex.firstMatch(in: trimmedLine, range: NSRange(trimmedLine.startIndex..., in: trimmedLine)),
           let dateRange = Range(match.range(at: 1), in: trimmedLine),
           let descriptionRange = Range(match.range(at: 3), in: trimmedLine),
           let withdrawRange = Range(match.range(at: 4), in: trimmedLine),
           let depositRange = Range(match.range(at: 5), in: trimmedLine),
           let balanceRange = Range(match.range(at: 6), in: trimmedLine) {
            parsedComponents = (
                dateString: String(trimmedLine[dateRange]),
                timeString: Range(match.range(at: 2), in: trimmedLine).map { String(trimmedLine[$0]) },
                description: String(trimmedLine[descriptionRange]),
                withdrawRaw: String(trimmedLine[withdrawRange]),
                depositRaw: String(trimmedLine[depositRange]),
                balanceRaw: String(trimmedLine[balanceRange])
            )
        } else {
            parsedComponents = parseTransactionLineFallback(trimmedLine, previousBalance: previousBalance)
        }

        guard let parsedComponents else { return nil }

        let normalizedTime = (parsedComponents.timeString?.isEmpty == false) ? parsedComponents.timeString : nil
        let dateString = parsedComponents.dateString
        guard let occurredAt = parseDate(dateString, time: normalizedTime) else { return nil }

        let description = parsedComponents.description
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)

        guard description.isEmpty == false else { return nil }
        guard description.caseInsensitiveCompare("Opening Balance") != .orderedSame,
              description.caseInsensitiveCompare("Closing Balance") != .orderedSame else {
            return nil
        }

        guard let withdrawAmount = parseAmountOrDash(parsedComponents.withdrawRaw),
              let depositAmount = parseAmountOrDash(parsedComponents.depositRaw),
              let balance = parseAmount(parsedComponents.balanceRaw) else {
            return nil
        }

        guard withdrawAmount > 0 || depositAmount > 0 else { return nil }

        return ImportedStatementTransaction(
            sequence: 0,
            occurredAt: occurredAt,
            description: description,
            withdrawAmount: withdrawAmount,
            depositAmount: depositAmount,
            balance: balance,
            externalReference: nil
        )
    }

    private static func parseTransactionLineFallback(_ line: String, previousBalance: Double? = nil) -> (dateString: String, timeString: String?, description: String, withdrawRaw: String, depositRaw: String, balanceRaw: String)? {
        guard let match = transactionPrefixRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
              let dateRange = Range(match.range(at: 1), in: line) else {
            return nil
        }

        let dateString = String(line[dateRange])
        let timeString = Range(match.range(at: 2), in: line).map { String(line[$0]) }
        let prefixEnd = Range(match.range, in: line)?.upperBound ?? line.startIndex
        let remainder = String(line[prefixEnd...]).trimmingCharacters(in: .whitespacesAndNewlines)

        let tokens = remainder
            .components(separatedBy: .whitespaces)
            .filter { $0.isEmpty == false }

        guard tokens.count >= 3 else { return nil }

        if tokens.count >= 4 {
            let trailingTokens = Array(tokens.suffix(3))
            if trailingTokens.allSatisfy(isAmountToken(_:)) {
                let descriptionTokens = tokens.dropLast(3)
                let description = descriptionTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                guard description.isEmpty == false else { return nil }

                return (
                    dateString: dateString,
                    timeString: timeString,
                    description: description,
                    withdrawRaw: trailingTokens[0],
                    depositRaw: trailingTokens[1],
                    balanceRaw: trailingTokens[2]
                )
            }
        }

        let trailingTokens = Array(tokens.suffix(2))
        guard trailingTokens.count == 2,
              trailingTokens.allSatisfy(isAmountToken(_:)),
              let amount = parseAmount(trailingTokens[0]),
              let balance = parseAmount(trailingTokens[1]) else {
            return nil
        }

        let descriptionTokens = tokens.dropLast(2)
        let description = descriptionTokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard description.isEmpty == false else { return nil }

        if let previousBalance {
            if amountsApproximatelyEqual(previousBalance - amount, balance) {
                return (
                    dateString: dateString,
                    timeString: timeString,
                    description: description,
                    withdrawRaw: trailingTokens[0],
                    depositRaw: "-",
                    balanceRaw: trailingTokens[1]
                )
            }

            if amountsApproximatelyEqual(previousBalance + amount, balance) {
                return (
                    dateString: dateString,
                    timeString: timeString,
                    description: description,
                    withdrawRaw: "-",
                    depositRaw: trailingTokens[0],
                    balanceRaw: trailingTokens[1]
                )
            }
        }

        if trailingTokens[0].localizedCaseInsensitiveContains("CR") {
            return (
                dateString: dateString,
                timeString: timeString,
                description: description,
                withdrawRaw: "-",
                depositRaw: trailingTokens[0],
                balanceRaw: trailingTokens[1]
            )
        }

        if trailingTokens[0].localizedCaseInsensitiveContains("DR") {
            return (
                dateString: dateString,
                timeString: timeString,
                description: description,
                withdrawRaw: trailingTokens[0],
                depositRaw: "-",
                balanceRaw: trailingTokens[1]
            )
        }

        return nil
    }

    static func buildTransactionBlocks(from lines: [String]) -> [String] {
        var blocks: [String] = []
        var currentBlock: String?

        for line in lines {
            if shouldIgnoreNonTransactionLine(line) {
                continue
            }

            if transactionStartRegex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) != nil {
                if let existingBlock = currentBlock {
                    let normalizedExistingBlock = existingBlock
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    if hasTransactionShape(normalizedExistingBlock) || isStatementBalanceMarkerLine(normalizedExistingBlock) {
                        blocks.append(existingBlock)
                        currentBlock = line
                    } else {
                        currentBlock = existingBlock + " " + line
                    }
                } else {
                    currentBlock = line
                }
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

    static func shouldIgnoreNonTransactionLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()

        if lowercased.hasPrefix("electronic account statement") ||
            lowercased.hasPrefix("statement of account") ||
            lowercased.hasPrefix("account holder") ||
            lowercased.hasPrefix("account name:") ||
            lowercased.hasPrefix("account number") ||
            lowercased.hasPrefix("interest rate") ||
            lowercased.hasPrefix("currency code") ||
            lowercased.hasPrefix("from:") ||
            lowercased.hasPrefix("to date") ||
            lowercased.hasPrefix("from date") ||
            lowercased.hasPrefix("date statement date") ||
            lowercased.hasPrefix("statement period") ||
            lowercased.hasPrefix("opening balance") ||
            lowercased.hasPrefix("balance from previous statement") ||
            lowercased.hasPrefix("closing balance") ||
            lowercased.hasPrefix("accrued interest") ||
            lowercased.hasPrefix("transaction date description") ||
            lowercased.hasPrefix("s.n cheque number") ||
            lowercased.hasPrefix("report generated on:") ||
            lowercased.hasPrefix("the statement reflects account transaction") ||
            lowercased.hasPrefix("intended to be utilized") ||
            lowercased.hasPrefix("branch.") ||
            lowercased.hasPrefix("branch :") ||
            lowercased.hasPrefix("hotline :") ||
            lowercased.hasPrefix("page of") ||
            lowercased.hasPrefix("switch to free e-statement service") ||
            lowercased.hasPrefix("get an easy access to your bank account") ||
            lowercased.hasPrefix("constant endeavor to keep our records updated") ||
            lowercased.hasPrefix("any changes to your personal particulars") ||
            lowercased.hasPrefix("you") {
            return true
        }

        let normalizedHeader = lowercased
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalizedHeader == "date description deposit withdrawal balance" ||
            normalizedHeader == "date description debit credit balance" ||
            normalizedHeader == "date description withdrawal deposit balance" {
            return true
        }

        if normalizedHeader.range(of: #"^page\s+\d+\s+of\s+\d+$"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return true
        }

        if normalizedHeader == "estatement" {
            return true
        }

        if line.range(of: #"^\d+$"#, options: .regularExpression) != nil ||
            line.range(of: #"^\d+\s+\d+$"#, options: .regularExpression) != nil ||
            line.range(of: #"^\d{2}-\d-\d{6,}-\d{2}\s+\([A-Z]{3}\)$"#, options: .regularExpression) != nil {
            return true
        }

        return false
    }

    static func extractBalance(label: String, from lines: [String]) -> Double? {
        extractBalance(labels: [label], from: lines)
    }

    static func extractBalance(labels: [String], from lines: [String]) -> Double? {
        for line in lines {
            let lowercased = line.lowercased()
            guard labels.contains(where: { lowercased.contains($0) }) else { continue }

            let matches = amountRegex.matches(in: line, range: NSRange(line.startIndex..., in: line))
            guard let match = matches.last, let range = Range(match.range, in: line) else { continue }
            let amountText = String(line[range])
            if let value = parseAmount(amountText) {
                return value
            }
        }

        return nil
    }

    static func isStatementBalanceMarkerLine(_ line: String) -> Bool {
        let lowercased = line.lowercased()
        guard lowercased.contains("opening balance")
            || lowercased.contains("balance from previous statement")
            || lowercased.contains("closing balance") else {
            return false
        }

        return extractBalance(
            labels: ["opening balance", "balance from previous statement", "closing balance"],
            from: [line]
        ) != nil
    }

    static func hasTransactionShape(_ line: String) -> Bool {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if statementLineRegex.firstMatch(in: trimmedLine, range: NSRange(trimmedLine.startIndex..., in: trimmedLine)) != nil {
            return true
        }

        guard let match = transactionPrefixRegex.firstMatch(in: trimmedLine, range: NSRange(trimmedLine.startIndex..., in: trimmedLine)),
              let prefixRange = Range(match.range, in: trimmedLine) else {
            return false
        }

        let remainder = String(trimmedLine[prefixRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = remainder
            .components(separatedBy: .whitespaces)
            .filter { $0.isEmpty == false }

        if tokens.count >= 4 {
            let trailingThree = Array(tokens.suffix(3))
            if trailingThree.allSatisfy(isAmountToken(_:)) {
                let description = tokens.dropLast(3).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if description.isEmpty == false {
                    return true
                }
            }
        }

        if tokens.count >= 3 {
            let trailingTwo = Array(tokens.suffix(2))
            if trailingTwo.allSatisfy(isAmountToken(_:)) {
                let description = tokens.dropLast(2).joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if description.isEmpty == false {
                    return true
                }
            }
        }

        return false
    }

    static func parseAmount(_ value: String) -> Double? {
        let cleaned = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "CR", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "DR", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Double(cleaned)
    }

    static func parseAmountOrDash(_ value: String) -> Double? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "-" {
            return 0
        }
        return parseAmount(trimmed)
    }

    static func parseDate(_ value: String, time: String? = nil) -> Date? {
        let dateFormats = [
            "yyyy-MM-dd",
            "dd/MM/yyyy",
            "d/M/yyyy",
            "dd-MM-yyyy",
            "d-M-yyyy",
            "dd/MM/yy",
            "dd-MM-yy",
            "dd MMM yyyy",
            "d MMM yyyy",
            "dd MMM yy"
        ]

        if let time, time.isEmpty == false {
            let normalizedTime = normalizedTimeString(time)
            for dateFormat in dateFormats {
                for timeFormat in ["HH:mm", "HH:mm:ss"] {
                    let formatter = self.formatter("\(dateFormat) \(timeFormat)")
                    if let date = formatter.date(from: "\(value) \(normalizedTime)") {
                        return date
                    }
                }
            }
        }

        for dateFormat in dateFormats {
            let formatter = self.formatter(dateFormat)
            if let date = formatter.date(from: value) {
                return date
            }
        }

        return nil
    }

    private static func normalizedTimeString(_ value: String) -> String {
        value.replacingOccurrences(of: "::", with: ":")
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
        pattern: #"^\s*(\d{4}-\d{2}-\d{2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4})\b"#,
        options: [.caseInsensitive]
    )

    private static let transactionPrefixRegex = try! NSRegularExpression(
        pattern: #"^\s*(\d{4}-\d{2}-\d{2}|\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d{1,2}\s+[A-Za-z]{3}\s+\d{2,4})(?:\s+(\d{2}:\d{2}:?(?::\d{2})?))?\s+"#,
        options: [.caseInsensitive]
    )

    private static let amountRegex = try! NSRegularExpression(
        pattern: #"-?\d[\d,]*(?:\.\d{1,2})?"#,
        options: []
    )

    private static func isAmountToken(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "-" {
            return true
        }

        let pattern = #"^\d[\d,]*(?:\.\d{1,2})?(?:\s?(?:CR|DR))?$"#
        return trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }

    private static func amountsApproximatelyEqual(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) < 0.01
    }
}
