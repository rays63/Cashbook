import Foundation
import PDFKit

enum BankStatementPDFImportService {
    static func parseStatement(from url: URL) throws -> StatementImportPreview {
        guard let document = PDFDocument(url: url) else {
            throw PDFImportError.invalidPDF
        }
        let parsed = PDFStatementParser.parse(document: document)

        return StatementImportPreview(
            sourceURL: url,
            transactions: parsed.transactions,
            ignoredLineCount: parsed.ignoredLineCount,
            duplicateLineCount: 0,
            duplicateTransactions: [],
            openingBalance: parsed.openingBalance,
            closingBalance: parsed.closingBalance
        )
    }
}

enum PDFImportError: LocalizedError {
    case invalidPDF
    case noTransactionsFound
    case allTransactionsDuplicate

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            "The selected file could not be read as a PDF."
        case .noTransactionsFound:
            "No valid transactions were found in the selected PDF."
        case .allTransactionsDuplicate:
            "Everything in this statement is already in this book, so there is nothing new to import."
        }
    }
}
