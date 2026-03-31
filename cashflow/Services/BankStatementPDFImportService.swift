import Foundation
import PDFKit

enum BankStatementPDFImportService {
    static func parseStatement(from url: URL, password: String? = nil) throws -> StatementImportPreview {
        guard let document = PDFDocument(url: url) else {
            throw PDFImportError.invalidPDF
        }

        if document.isLocked {
            guard let password, password.isEmpty == false else {
                throw PDFImportError.passwordRequired
            }

            guard document.unlock(withPassword: password) else {
                throw PDFImportError.invalidPassword
            }
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
    case passwordRequired
    case invalidPassword

    var errorDescription: String? {
        switch self {
        case .invalidPDF:
            "The selected file could not be read as a PDF."
        case .noTransactionsFound:
            "No valid transactions were found in the selected PDF."
        case .allTransactionsDuplicate:
            "Everything in this statement is already in this book, so there is nothing new to import."
        case .passwordRequired:
            "This PDF is password protected."
        case .invalidPassword:
            "The password for this PDF is incorrect."
        }
    }
}
