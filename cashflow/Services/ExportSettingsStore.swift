import Combine
import Foundation

@MainActor
final class ExportSettingsStore: ObservableObject {
    @Published var selectedFields: Set<ExportField> = Set(ExportField.allCases)

    private let defaultsKey = "cashbook.export.fields"

    init() {
        load()
    }

    func toggle(_ field: ExportField) {
        if selectedFields.contains(field), selectedFields.count > 1 {
            selectedFields.remove(field)
        } else {
            selectedFields.insert(field)
        }
        persist()
    }

    func orderedFields() -> [ExportField] {
        ExportField.allCases.filter(selectedFields.contains)
    }

    private func load() {
        guard let rawValues = UserDefaults.standard.array(forKey: defaultsKey) as? [String] else { return }
        let fields = rawValues.compactMap(ExportField.init(rawValue:))
        if fields.isEmpty == false {
            selectedFields = Set(fields)
        }
    }

    private func persist() {
        UserDefaults.standard.set(selectedFields.map(\.rawValue), forKey: defaultsKey)
    }
}
