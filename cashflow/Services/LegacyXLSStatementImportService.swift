import Foundation
import JavaScriptCore

enum LegacyXLSStatementImportService {
    static func parseStatement(from url: URL) throws -> StatementImportPreview {
        let rows = try workbookRows(from: url)
        let headerIndex = rows.firstIndex(where: isHeaderRow(_:)) ?? 0
        let dataRows = rows.dropFirst(headerIndex + 1)

        var transactions: [ImportedStatementTransaction] = []
        var ignoredLineCount = 0

        for row in dataRows {
            if isSummaryRow(row) { continue }

            guard let transaction = parseTransaction(from: row) else {
                if row.contains(where: { $0.isEmpty == false }) {
                    ignoredLineCount += 1
                }
                continue
            }

            transactions.append(transaction)
        }

        return StatementImportPreview(
            sourceURL: url,
            transactions: transactions,
            ignoredLineCount: ignoredLineCount,
            duplicateLineCount: 0
        )
    }

    private static func workbookRows(from url: URL) throws -> [[String]] {
        let data = try Data(contentsOf: url)
        let base64 = data.base64EncodedString()

        let context = JSContext()
        context?.exceptionHandler = { _, exception in
            if let exception {
                print("SheetJS exception: \(exception)")
            }
        }

        let scriptURL =
            Bundle.main.url(forResource: "xlsx.full.min", withExtension: "js") ??
            Bundle.main.url(forResource: "xlsx.full.min", withExtension: "js", subdirectory: "Resources")

        guard let scriptURL,
              let script = try? String(contentsOf: scriptURL) else {
            throw XLSImportError.parserUnavailable
        }

        context?.evaluateScript(script)
        context?.evaluateScript(
            """
            function parseWorkbookRows(base64) {
              var workbook = XLSX.read(base64, { type: "base64" });
              var firstSheet = workbook.Sheets[workbook.SheetNames[0]];
              return JSON.stringify(XLSX.utils.sheet_to_json(firstSheet, { header: 1, defval: "", raw: false }));
            }
            """
        )

        guard let parseFunction = context?.objectForKeyedSubscript("parseWorkbookRows"),
              let result = parseFunction.call(withArguments: [base64])?.toString(),
              let jsonData = result.data(using: .utf8),
              let rows = try JSONSerialization.jsonObject(with: jsonData) as? [[Any]] else {
            throw XLSImportError.invalidWorkbook
        }

        return rows.map { row in
            row.map { cell in
                String(describing: cell)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    private static func isHeaderRow(_ row: [String]) -> Bool {
        row.count >= 7 &&
        row[0].caseInsensitiveCompare("Reference Code") == .orderedSame &&
        row[1].caseInsensitiveCompare("Date Time") == .orderedSame &&
        row[2].caseInsensitiveCompare("Description") == .orderedSame
    }

    private static func isSummaryRow(_ row: [String]) -> Bool {
        guard let firstValue = row.first?.lowercased() else { return true }
        return firstValue.isEmpty ||
            firstValue == "total" ||
            firstValue == "pending" ||
            firstValue == "complete" ||
            firstValue == "canceled"
    }

    private static func parseTransaction(from row: [String]) -> ImportedStatementTransaction? {
        guard row.count >= 7 else { return nil }

        let referenceCode = row[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let dateText = row[1].trimmingCharacters(in: .whitespacesAndNewlines)
        let description = row[2].trimmingCharacters(in: .whitespacesAndNewlines)
        let withdraw = parseAmount(row[3])
        let deposit = parseAmount(row[4])
        let balance = parseAmount(row[6])

        guard referenceCode.isEmpty == false,
              let occurredAt = parseDate(dateText),
              let balance else { return nil }

        let hasWithdraw = (withdraw ?? 0) > 0
        let hasDeposit = (deposit ?? 0) > 0
        guard hasWithdraw || hasDeposit else { return nil }

        let normalizedDescription = description.isEmpty ? "Statement Entry" : description

        return ImportedStatementTransaction(
            occurredAt: occurredAt,
            description: normalizedDescription,
            withdrawAmount: hasWithdraw ? (withdraw ?? 0) : 0,
            depositAmount: hasDeposit ? (deposit ?? 0) : 0,
            balance: balance,
            externalReference: referenceCode
        )
    }

    private static func parseAmount(_ value: String) -> Double? {
        let cleaned = value
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleaned.isEmpty == false else { return nil }
        return Double(cleaned)
    }

    private static func parseDate(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.S"
        return formatter.date(from: value)
    }
}

private enum XLSImportError: LocalizedError {
    case parserUnavailable
    case invalidWorkbook

    var errorDescription: String? {
        switch self {
        case .parserUnavailable:
            return "The XLS parser resource is missing from the app bundle."
        case .invalidWorkbook:
            return "The selected XLS statement could not be read."
        }
    }
}
