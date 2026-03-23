import Foundation
import UIKit

enum ReportExportService {
    static func exportPDF(book: BookEntity, snapshot: ReportSnapshot, fields: [ExportField]) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\((book.name ?? "Book").replacingOccurrences(of: " ", with: "_"))_\(snapshot.type.rawValue)_\(AppFormatters.exportTimestamp.string(from: .now)).pdf")

        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        try renderer.writePDF(to: fileURL) { context in
            context.beginPage()

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold)
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .regular)
            ]

            var y: CGFloat = 28
            "\((book.name ?? "Book")) Report".draw(at: CGPoint(x: 28, y: y), withAttributes: titleAttributes)
            y += 36
            "Type: \(snapshot.type.rawValue)".draw(at: CGPoint(x: 28, y: y), withAttributes: bodyAttributes)
            y += 20
            "Generated: \(AppFormatters.bookDate.string(from: .now))".draw(at: CGPoint(x: 28, y: y), withAttributes: bodyAttributes)
            y += 30
            "Net Balance: \(AppFormatters.currencyString(for: snapshot.netBalance))".draw(at: CGPoint(x: 28, y: y), withAttributes: bodyAttributes)
            y += 18
            "Cash In: \(AppFormatters.currencyString(for: snapshot.totalCashIn))".draw(at: CGPoint(x: 28, y: y), withAttributes: bodyAttributes)
            y += 18
            "Cash Out: \(AppFormatters.currencyString(for: snapshot.totalCashOut))".draw(at: CGPoint(x: 28, y: y), withAttributes: bodyAttributes)
            y += 28

            for row in snapshot.rows {
                if y > 740 {
                    context.beginPage()
                    y = 28
                }

                let rowText = renderExportLine(for: row, fields: fields)
                rowText.draw(in: CGRect(x: 28, y: y, width: 556, height: 40), withAttributes: bodyAttributes)
                y += 40
            }
        }

        return fileURL
    }

    static func exportExcel(book: BookEntity, snapshot: ReportSnapshot, fields: [ExportField]) throws -> URL {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\((book.name ?? "Book").replacingOccurrences(of: " ", with: "_"))_\(snapshot.type.rawValue)_\(AppFormatters.exportTimestamp.string(from: .now)).xls")

        let header = fields.map(\.rawValue)
        let rows = snapshot.rows.map { row in
            fields.map { value(for: $0, row: row) }
        }

        var xml = """
        <?xml version="1.0"?>
        <Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"
         xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">
        <Worksheet ss:Name="Report">
        <Table>
        """

        xml += xmlRow(header)
        rows.forEach { xml += xmlRow($0) }
        xml += """
        </Table>
        </Worksheet>
        </Workbook>
        """

        try xml.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL
    }

    private static func renderExportLine(for row: ReportRow, fields: [ExportField]) -> String {
        fields.map { "\($0.rawValue): \(value(for: $0, row: row))" }.joined(separator: "    ")
    }

    private static func value(for field: ExportField, row: ReportRow) -> String {
        switch field {
        case .name:
            row.subtitle.components(separatedBy: " • ").first ?? row.subtitle
        case .title:
            row.title
        case .amount:
            AppFormatters.currencyString(for: row.amount)
        case .time:
            row.subtitle
        case .balance:
            AppFormatters.currencyString(for: row.balance ?? 0)
        case .category:
            row.subtitle.components(separatedBy: " • ").dropFirst().first ?? "-"
        case .paymentMode:
            row.subtitle.components(separatedBy: " • ").last ?? "-"
        }
    }

    private static func xmlRow(_ values: [String]) -> String {
        let cells = values.map { "<Cell><Data ss:Type=\"String\">\(escaped($0))</Data></Cell>" }.joined()
        return "<Row>\(cells)</Row>"
    }

    private static func escaped(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
