import Charts
import CoreData
import SwiftUI

struct ReportsHubView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.updatedAt, ascending: false)],
        animation: .smooth
    )
    private var books: FetchedResults<BookEntity>

    @State private var selectedBookFilter: ReportsBookFilter = .allBooks
    @State private var selectedDateFilter: DateRangePreset = .thisMonth

    private var filteredBooks: [BookEntity] {
        switch selectedBookFilter {
        case .allBooks:
            return Array(books)
        case .book(let id):
            return books.filter { $0.objectID == id }
        }
    }

    private var filteredTransactions: [TransactionEntry] {
        let calendar = Calendar.current
        let base = filteredBooks.flatMap(\.transactionArray)

        return base
            .filter { entry in
                let occurredAt = entry.occurredAt ?? .distantPast
                switch selectedDateFilter {
                case .all:
                    return true
                case .today:
                    return calendar.isDateInToday(occurredAt)
                case .last7Days:
                    return occurredAt >= (calendar.date(byAdding: .day, value: -7, to: .now) ?? .distantPast)
                case .thisMonth:
                    return calendar.isDate(occurredAt, equalTo: .now, toGranularity: .month)
                }
            }
            .sorted { ($0.occurredAt ?? .distantPast) < ($1.occurredAt ?? .distantPast) }
    }

    private var totalCashIn: Double {
        filteredTransactions.filter { $0.transactionKind == .cashIn }.reduce(0) { $0 + $1.amount }
    }

    private var totalCashOut: Double {
        filteredTransactions.filter { $0.transactionKind == .cashOut }.reduce(0) { $0 + $1.amount }
    }

    private var netCashflow: Double {
        totalCashIn - totalCashOut
    }

    private var chartPoints: [CashflowChartPoint] {
        let grouped = Dictionary(grouping: filteredTransactions) {
            Calendar.current.startOfDay(for: $0.occurredAt ?? .distantPast)
        }

        return grouped.keys.sorted().map { date in
            let entries = grouped[date] ?? []
            let income = entries.filter { $0.transactionKind == .cashIn }.reduce(0) { $0 + $1.amount }
            let expense = entries.filter { $0.transactionKind == .cashOut }.reduce(0) { $0 + $1.amount }
            return CashflowChartPoint(date: date, income: income, expense: expense)
        }
    }

    private var categoryRows: [CategoryInsightRow] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.category?.wrappedName ?? "Uncategorized" }
        return grouped.map { key, value in
            CategoryInsightRow(
                title: key,
                amount: value.reduce(0) { $0 + abs($1.signedAmount) },
                transactionCount: value.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var paymentModeRows: [CategoryInsightRow] {
        let grouped = Dictionary(grouping: filteredTransactions) { $0.paymentMode?.wrappedName ?? "Unknown" }
        return grouped.map { key, value in
            CategoryInsightRow(
                title: key,
                amount: value.reduce(0) { $0 + abs($1.signedAmount) },
                transactionCount: value.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private var insightText: String {
        if filteredTransactions.isEmpty {
            return "Add a few cash in and cash out entries to unlock spending and income insights."
        }

        let topCategory = categoryRows.first?.title ?? "your categories"
        if totalCashIn >= totalCashOut {
            return "Income is ahead for the selected period. \(topCategory) is seeing the strongest movement right now."
        } else {
            return "Spending is ahead for the selected period. Review \(topCategory) and recent payment modes to tighten the budget."
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        filterCards
                        metricCards
                        insightsCard
                        trendChartCard
                        breakdownSection(title: "Top Categories", rows: categoryRows, tint: .orange)
                        breakdownSection(title: "Payment Modes", rows: paymentModeRows, tint: AppTheme.accent)
                        detailedReportsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reports")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            Text("Budget, spending, and income insights")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            Text("Visualize how money moves with filters across books, dates, categories, and payment modes.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var filterCards: some View {
        VStack(spacing: 12) {
            filterMenu(
                title: "Book",
                value: selectedBookFilter.title(using: Array(books))
            ) {
                Picker("Book", selection: $selectedBookFilter) {
                    Text("All Books").tag(ReportsBookFilter.allBooks)
                    ForEach(Array(books), id: \.objectID) { book in
                        Text(book.name ?? "Untitled Book").tag(ReportsBookFilter.book(book.objectID))
                    }
                }
            }

            filterMenu(
                title: "Period",
                value: selectedDateFilter.rawValue
            ) {
                Picker("Period", selection: $selectedDateFilter) {
                    ForEach(DateRangePreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
            }
        }
    }

    private var metricCards: some View {
        HStack(spacing: 12) {
            metricCard(title: "Income", value: totalCashIn, tint: AppTheme.success)
            metricCard(title: "Spent", value: totalCashOut, tint: AppTheme.danger)
            metricCard(title: "Net", value: netCashflow, tint: netCashflow >= 0 ? AppTheme.accent : .orange)
        }
    }

    private var insightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insights")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
            Text(insightText)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppTheme.accent.opacity(0.94), AppTheme.success.opacity(0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .foregroundStyle(.white)
        .shadow(color: AppTheme.accent.opacity(0.24), radius: 20, x: 0, y: 12)
    }

    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cashflow Trend")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            if chartPoints.isEmpty {
                EmptyStateView(
                    title: "No chart data",
                    message: "Transactions in the selected filter will appear here as visual trends.",
                    systemImage: "chart.xyaxis.line"
                )
            } else {
                Chart {
                    ForEach(chartPoints) { point in
                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Income", point.income)
                        )
                        .foregroundStyle(AppTheme.success.gradient)

                        BarMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Expense", point.expense)
                        )
                        .foregroundStyle(AppTheme.danger.gradient)
                        .opacity(0.7)
                    }

                    ForEach(chartPoints) { point in
                        LineMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Net", point.income - point.expense)
                        )
                        .foregroundStyle(AppTheme.accent)
                        .lineStyle(.init(lineWidth: 3, lineCap: .round))
                    }
                }
                .frame(height: 240)
                .chartLegend(position: .bottom, spacing: 18)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding(20)
        .appCardStyle(cornerRadius: 28)
    }

    private func breakdownSection(title: String, rows: [CategoryInsightRow], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            if rows.isEmpty {
                EmptyStateView(
                    title: "No data yet",
                    message: "Use the filters above to explore more breakdowns once transactions are available.",
                    systemImage: "chart.bar.doc.horizontal"
                )
            } else {
                ForEach(Array(rows.prefix(4))) { row in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(row.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer()
                            Text(AppFormatters.currencyString(for: row.amount))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(tint)
                        }

                        Text("\(row.transactionCount) transactions")
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)

                        ProgressView(value: row.amount, total: max(rows.first?.amount ?? row.amount, 1))
                            .tint(tint)
                    }
                    .padding(16)
                    .background(AppTheme.listRowFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(20)
        .appCardStyle(cornerRadius: 28)
    }

    private var detailedReportsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Detailed Reports")
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            if books.isEmpty {
                EmptyStateView(
                    title: "No books yet",
                    message: "Create a book to open exports and the existing detailed report screen.",
                    systemImage: "doc.text.magnifyingglass"
                )
            } else {
                ForEach(Array(books.prefix(4)), id: \.objectID) { book in
                    NavigationLink {
                        ReportView(book: book, detailViewModel: BookDetailViewModel(book: book))
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.name ?? "Untitled Book")
                                    .font(.headline.weight(.semibold))
                                    .foregroundStyle(AppTheme.primaryText)
                                Text("\(book.transactionArray.count) entries")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            Spacer()
                            Text(AppFormatters.currencyString(for: book.balance))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(book.balance >= 0 ? AppTheme.success : AppTheme.danger)
                        }
                        .padding(16)
                        .background(AppTheme.listRowFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .appCardStyle(cornerRadius: 28)
    }

    private func filterMenu<Content: View>(title: String, value: String, @ViewBuilder content: () -> Content) -> some View {
        Menu {
            content()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(value)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(16)
            .appCardStyle(cornerRadius: 22)
        }
        .buttonStyle(.plain)
    }

    private func metricCard(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(AppFormatters.currencyString(for: value))
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .appCardStyle(cornerRadius: 24)
    }
}

private struct CashflowChartPoint: Identifiable {
    let id = UUID()
    let date: Date
    let income: Double
    let expense: Double
}

private struct CategoryInsightRow: Identifiable {
    let id = UUID()
    let title: String
    let amount: Double
    let transactionCount: Int
}

private enum ReportsBookFilter: Hashable {
    case allBooks
    case book(NSManagedObjectID)

    func title(using books: [BookEntity]) -> String {
        switch self {
        case .allBooks:
            return "All Books"
        case .book(let id):
            return books.first(where: { $0.objectID == id })?.name ?? "Selected Book"
        }
    }
}
