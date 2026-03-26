import Foundation
import CoreData

enum TransactionKind: Int16, CaseIterable, Identifiable {
    case cashIn = 0
    case cashOut = 1

    var id: Int16 { rawValue }

    var title: String {
        switch self {
        case .cashIn: "Cash In"
        case .cashOut: "Cash Out"
        }
    }

    var amountPrefix: String {
        switch self {
        case .cashIn: "+"
        case .cashOut: "-"
        }
    }
}

enum BookSortOption: String, CaseIterable, Identifiable {
    case updatedAt = "Last Updated"
    case name = "Name"
    case balance = "Balance"

    var id: String { rawValue }
}

enum ReportType: String, CaseIterable, Identifiable {
    case allEntries = "All Entries"
    case dayWise = "Day-wise"
    case categoryWise = "Category-wise"
    case paymentMode = "Payment Mode"

    var id: String { rawValue }
}

enum DateRangePreset: String, CaseIterable, Identifiable {
    case all = "All Dates"
    case today = "Today"
    case last7Days = "Last 7 Days"
    case thisMonth = "This Month"

    var id: String { rawValue }
}

enum ExportField: String, CaseIterable, Identifiable {
    case name = "Name"
    case title = "Title"
    case amount = "Amount"
    case time = "Time"
    case balance = "Balance"
    case category = "Category"
    case paymentMode = "Payment Mode"

    var id: String { rawValue }
}

struct TransactionFilterState {
    var datePreset: DateRangePreset = .all
    var kind: TransactionKind?
    var categoryName: String = "All"
    var paymentModeName: String = "All"

    var isActive: Bool {
        datePreset != .all || kind != nil || categoryName != "All" || paymentModeName != "All"
    }
}

struct ReportRow: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let amount: Double
    let balance: Double?
}

struct ReportSnapshot {
    let type: ReportType
    let rows: [ReportRow]
    let totalCashIn: Double
    let totalCashOut: Double
    let netBalance: Double
}

struct TransactionDraft {
    var type: TransactionKind = .cashIn
    var amountText: String = ""
    var title: String = ""
    var categoryName: String = ""
    var paymentModeName: String = ""
    var goalName: String = ""
    var occurredAt: Date = .now
    var notes: String = ""

    var amountValue: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: ""))
    }
}

enum CatalogKind {
    case category
    case paymentMode

    var title: String {
        switch self {
        case .category: "Categories"
        case .paymentMode: "Payment Modes"
        }
    }

    var singularTitle: String {
        switch self {
        case .category: "Category"
        case .paymentMode: "Payment Mode"
        }
    }

    var editOptionTitle: String {
        switch self {
        case .category: "Edit Categories"
        case .paymentMode: "Edit Payment Modes"
        }
    }
}

struct ImportedStatementTransaction: Identifiable {
    let id = UUID()
    let occurredAt: Date
    let description: String
    let withdrawAmount: Double
    let depositAmount: Double
    let balance: Double
    let externalReference: String?

    var transactionKind: TransactionKind {
        depositAmount > 0 ? .cashIn : .cashOut
    }

    var transactionAmount: Double {
        depositAmount > 0 ? depositAmount : withdrawAmount
    }
}

struct StatementImportPreview {
    let sourceURL: URL
    let transactions: [ImportedStatementTransaction]
    let ignoredLineCount: Int
    let duplicateLineCount: Int
}

enum AppTab: String, CaseIterable, Identifiable {
    case home
    case calendar
    case reports
    case goals
    case settings
    case books

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: "Home"
        case .calendar: "Calendar"
        case .reports: "Reports"
        case .goals: "Goals"
        case .settings: "Settings"
        case .books: "Books"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house"
        case .calendar: "calendar"
        case .reports: "chart.bar"
        case .goals: "target"
        case .settings: "gearshape"
        case .books: "book.closed"
        }
    }
}

struct GoalDraft {
    var name: String = ""
    var budgetText: String = ""
    var hasDeadline = false
    var deadline: Date = .now

    var budgetValue: Double? {
        Double(budgetText.replacingOccurrences(of: ",", with: ""))
    }
}
