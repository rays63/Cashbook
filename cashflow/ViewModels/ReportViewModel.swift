import Combine
import Foundation

@MainActor
final class ReportViewModel: ObservableObject {
    @Published var selectedType: ReportType = .allEntries
    @Published var isExporting = false
    @Published var exportedURL: URL?
    @Published var errorMessage: String?

    func export(book: BookEntity, snapshot: ReportSnapshot, fields: [ExportField], asPDF: Bool) {
        isExporting = true
        defer { isExporting = false }

        do {
            exportedURL = try asPDF
                ? ReportExportService.exportPDF(book: book, snapshot: snapshot, fields: fields)
                : ReportExportService.exportExcel(book: book, snapshot: snapshot, fields: fields)
        } catch {
            errorMessage = "Unable to generate the export file."
        }
    }
}
