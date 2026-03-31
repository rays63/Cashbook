import CoreData
import SwiftUI

struct CalendarOverviewView: View {
    @AppStorage("cashbook.settings.calendarHighlights") private var calendarHighlightsEnabled = true

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.updatedAt, ascending: false)],
        animation: .smooth
    )
    private var books: FetchedResults<BookEntity>

    @State private var displayedMonth = Calendar.current.startOfMonth(for: .now)
    @State private var selectedDate = Calendar.current.startOfDay(for: .now)

    private let calendar = Calendar.current

    private var allTransactions: [TransactionEntry] {
        books.flatMap(\.transactionArray)
    }

    private var monthTransactions: [TransactionEntry] {
        allTransactions.filter { calendar.isDate($0.occurredAt ?? .distantPast, equalTo: displayedMonth, toGranularity: .month) }
    }

    private var selectedDayTransactions: [TransactionEntry] {
        monthTransactions
            .filter { calendar.isDate($0.occurredAt ?? .distantPast, inSameDayAs: selectedDate) }
            .sorted { ($0.occurredAt ?? .distantPast) > ($1.occurredAt ?? .distantPast) }
    }

    private var monthCashIn: Double {
        monthTransactions.filter { $0.transactionKind == .cashIn }.reduce(0) { $0 + $1.amount }
    }

    private var monthCashOut: Double {
        monthTransactions.filter { $0.transactionKind == .cashOut }.reduce(0) { $0 + $1.amount }
    }

    private var monthNet: Double {
        monthCashIn - monthCashOut
    }

    private var days: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else { return [] }

        var dates: [Date] = []
        var current = firstWeek.start
        while current < lastWeek.end {
            dates.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return dates
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        monthlySummary
                        calendarGrid
                        selectedDaySection
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
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calendar")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text(monthTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()

            HStack(spacing: 10) {
                monthButton(systemImage: "chevron.left") {
                    shiftMonth(by: -1)
                }
                monthButton(systemImage: "chevron.right") {
                    shiftMonth(by: 1)
                }
            }
        }
    }

    private var monthlySummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monthly Cashflow")
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)

            HStack(spacing: 14) {
                summaryMetric(title: "In", value: monthCashIn, tint: AppTheme.success)
                summaryMetric(title: "Out", value: monthCashOut, tint: AppTheme.danger)
                summaryMetric(title: "Net", value: monthNet, tint: AppTheme.accent)
            }
        }
        .padding(22)
        .appCardStyle(cornerRadius: 28)
    }

    private var calendarGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(calendar.shortStandaloneWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                }

                ForEach(days, id: \.self) { day in
                    dayCell(for: day)
                }
            }
        }
        .padding(18)
        .appCardStyle(cornerRadius: 28)
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Activity on \(AppFormatters.sectionDate.string(from: selectedDate))")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            if selectedDayTransactions.isEmpty {
                EmptyStateView(
                    title: "No entries on this day",
                    message: "Try another date or switch to a month with activity.",
                    systemImage: "calendar.badge.exclamationmark"
                )
            } else {
                ForEach(selectedDayTransactions, id: \.objectID) { transaction in
                    CalendarTransactionRow(transaction: transaction)
                }
            }
        }
    }

    private func dayCell(for day: Date) -> some View {
        let isCurrentMonth = calendar.isDate(day, equalTo: displayedMonth, toGranularity: .month)
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let items = transactions(on: day)
        let amount = items.reduce(0) { $0 + $1.signedAmount }

        return Button {
            selectedDate = day
        } label: {
            VStack(spacing: 6) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(.semibold))
                if calendarHighlightsEnabled, items.isEmpty == false {
                    Circle()
                        .fill(amount >= 0 ? AppTheme.success : AppTheme.danger)
                        .frame(width: 6, height: 6)
                } else {
                    Spacer()
                        .frame(height: 6)
                }
            }
            .foregroundStyle(isSelected ? Color.white : (isCurrentMonth ? AppTheme.primaryText : AppTheme.secondaryText.opacity(0.45)))
            .frame(maxWidth: .infinity, minHeight: 52)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isSelected ? AppTheme.accent : AppTheme.listRowFill)
            }
        }
        .buttonStyle(.plain)
    }

    private func summaryMetric(title: String, value: Double, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(AppFormatters.currencyString(for: value))
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func monthButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryText)
                .frame(width: 42, height: 42)
                .background(AppTheme.cardFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private func shiftMonth(by value: Int) {
        guard let next = calendar.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = calendar.startOfMonth(for: next)
        if calendar.isDate(selectedDate, equalTo: displayedMonth, toGranularity: .month) == false {
            selectedDate = displayedMonth
        }
    }

    private func transactions(on date: Date) -> [TransactionEntry] {
        monthTransactions.filter { calendar.isDate($0.occurredAt ?? .distantPast, inSameDayAs: date) }
    }
}

private struct CalendarTransactionRow: View {
    @ObservedObject var transaction: TransactionEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(transaction.book?.name ?? "Book")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentSoft, in: Capsule())

                    Text(transaction.category?.wrappedName ?? "General")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background((transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger).opacity(0.12), in: Capsule())

                    Text(transaction.title ?? "Untitled Entry")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text(transaction.transactionKind.title)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("\(transaction.transactionKind.amountPrefix)\(AppFormatters.currencyString(for: transaction.amount))")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(transaction.transactionKind == .cashIn ? AppTheme.success : AppTheme.danger)
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.importedStatementBalance != nil ? "Statement Balance" : "Running Balance")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(AppFormatters.currencyString(for: transaction.displayBalance))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }
                Spacer()
                Text("By \(transaction.editorName ?? "You") • \(AppFormatters.timeOnly.string(from: transaction.occurredAt ?? .now))")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(18)
        .appCardStyle(cornerRadius: 22)
    }
}

private extension Calendar {
    func startOfMonth(for referenceDate: Date) -> Date {
         self.date(from: dateComponents([.year, .month], from: referenceDate)) ?? referenceDate
    }
}
