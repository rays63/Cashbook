import CoreData
import SwiftUI

struct HomeDashboardView: View {
    @Binding var selectedTab: AppTab
    @AppStorage("cashbook.settings.quickInsights") private var quickInsightsEnabled = true
    @State private var selectedBook: BookEntity?

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \BookEntity.updatedAt, ascending: false)],
        animation: .smooth
    )
    private var books: FetchedResults<BookEntity>

    private var allTransactions: [TransactionEntry] {
        books.flatMap(\.transactionArray)
            .sorted { ($0.occurredAt ?? .distantPast) > ($1.occurredAt ?? .distantPast) }
    }

    private var totalBalance: Double {
        books.reduce(0) { $0 + $1.balance }
    }

    private var monthlyTransactions: [TransactionEntry] {
        let calendar = Calendar.current
        return allTransactions.filter { calendar.isDate($0.occurredAt ?? .distantPast, equalTo: .now, toGranularity: .month) }
    }

    private var monthCashIn: Double {
        monthlyTransactions.filter { $0.transactionKind == .cashIn }.reduce(0) { $0 + $1.amount }
    }

    private var monthCashOut: Double {
        monthlyTransactions.filter { $0.transactionKind == .cashOut }.reduce(0) { $0 + $1.amount }
    }

    private var recentBooks: [BookEntity] {
        Array(books.prefix(2))
    }

    var body: some View {
        ZStack {
            AppBackgroundView()

            if let selectedBook {
                BookDetailView(
                    book: selectedBook,
                    deleteAction: {
                        self.selectedBook = nil
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            self.selectedBook = nil
                        }
                    }
                )
                .transition(.move(edge: .trailing))
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        overviewCards
                        if quickInsightsEnabled {
                            insightCard
                        }
                        recentBooksSection
                        viewAllBooksButton
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("CashBook Pro")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                Text("Your wealth overview at a glance.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.accentSoft)
                    .frame(width: 54, height: 54)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(AppTheme.accent)
            }
        }
    }

    private var overviewCards: some View {
        VStack(spacing: 14) {
            dashboardCard(
                title: "Total Balance",
                value: AppFormatters.currencyString(for: totalBalance),
                subtitle: "\(books.count) book\(books.count == 1 ? "" : "s") tracked",
                tint: AppTheme.accent
            )

            HStack(spacing: 14) {
                dashboardCard(
                    title: "This Month In",
                    value: AppFormatters.currencyString(for: monthCashIn),
                    subtitle: "Cash in",
                    tint: AppTheme.success
                )
                dashboardCard(
                    title: "This Month Out",
                    value: AppFormatters.currencyString(for: monthCashOut),
                    subtitle: "Cash out",
                    tint: AppTheme.danger
                )
            }
        }
    }

    private var insightCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Smart Insights")
                .font(.headline.weight(.semibold))
            Text(monthCashIn >= monthCashOut ? "You are running positive this month. Keep using category filters to spot your strongest income streams." : "Spending is leading this month. Open the calendar to spot the busiest days and tighten expense categories.")
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                selectedTab = .calendar
            } label: {
                Label("Open Calendar View", systemImage: "calendar")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.16), in: Capsule())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [AppTheme.accent, AppTheme.success],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .shadow(color: AppTheme.accent.opacity(0.22), radius: 24, x: 0, y: 14)
        .foregroundStyle(.white)
    }

    private var recentBooksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Books")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            if recentBooks.isEmpty {
                EmptyStateView(
                    title: "No books yet",
                    message: "Create your first book to see balances, reports, and calendar activity here.",
                    systemImage: "book.closed"
                )
            } else {
                ForEach(recentBooks, id: \.objectID) { book in
                    Button {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            selectedBook = book
                        }
                    } label: {
                        BookRowCard(book: book)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func dashboardCard(title: String, value: String, subtitle: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Circle()
                .fill(tint.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Circle()
                        .fill(tint)
                        .frame(width: 16, height: 16)
                }

            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .minimumScaleFactor(0.8)
            Text(subtitle)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .appCardStyle(cornerRadius: 28)
    }

    private var viewAllBooksButton: some View {
        Button {
            selectedTab = .books
        } label: {
            Text("View All Books")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.success],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        }
        .buttonStyle(.plain)
    }
}
