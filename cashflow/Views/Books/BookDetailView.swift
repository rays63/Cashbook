import CoreData
import SwiftUI

struct BookDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var exportSettings: ExportSettingsStore
    @StateObject private var viewModel: BookDetailViewModel
    @StateObject private var reportViewModel = ReportViewModel()

    @State private var isShowingTransactionForm = false
    @State private var selectedKind: TransactionKind = .cashIn
    @State private var editingTransaction: TransactionEntry?
    @State private var viewingTransaction: TransactionEntry?
    @State private var showingReport = false
    @State private var shareURL: URL?
    @State private var isShowingBookEditor = false
    @State private var isShowingPDFPicker = false

    let deleteAction: () -> Void
    let onBack: (() -> Void)?

    init(book: BookEntity, deleteAction: @escaping () -> Void, onBack: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: BookDetailViewModel(book: book))
        self.deleteAction = deleteAction
        self.onBack = onBack
    }

    var body: some View {
        BookDetailContent(
            viewModel: viewModel,
            onShowReport: { showingReport = true },
            onCashIn: {
                selectedKind = .cashIn
                editingTransaction = nil
                isShowingTransactionForm = true
            },
            onCashOut: {
                selectedKind = .cashOut
                editingTransaction = nil
                isShowingTransactionForm = true
            },
            onEditTransaction: { transaction in
                editingTransaction = transaction
            },
            onDeleteTransaction: { transaction in
                viewModel.deleteTransaction(transaction)
            },
            onOpenTransaction: { transaction in
                viewingTransaction = transaction
            },
            onExportPDF: {
                let snapshot = viewModel.reportSnapshot(for: .allEntries)
                reportViewModel.export(book: viewModel.book, snapshot: snapshot, fields: exportSettings.orderedFields(), asPDF: true)
                shareURL = reportViewModel.exportedURL
            },
            onEditBook: { isShowingBookEditor = true },
            onImportPDF: { isShowingPDFPicker = true },
            onShareReport: {
                let snapshot = viewModel.reportSnapshot(for: .allEntries)
                reportViewModel.export(book: viewModel.book, snapshot: snapshot, fields: exportSettings.orderedFields(), asPDF: true)
                shareURL = reportViewModel.exportedURL
            },
            onBack: { onBack?() },
            onDeleteBook: {
                deleteAction()
                onBack?()
            }
        )
        .task {
            viewModel.configure(context: context)
        }
        .sheet(isPresented: $isShowingTransactionForm) {
            TransactionFormView(
                book: viewModel.book,
                initialDraft: TransactionDraft(type: selectedKind),
                title: selectedKind.title,
                goalOptions: viewModel.goalOptions
            ) { draft in
                let saved = viewModel.saveTransaction(draft: draft, editing: nil)
                if saved {
                    isShowingTransactionForm = false
                }
                return saved
            }
        }
        .sheet(item: $editingTransaction) { transaction in
            TransactionFormView(
                book: viewModel.book,
                initialDraft: TransactionDraft(
                    type: transaction.transactionKind,
                    amountText: String(format: "%.2f", transaction.amount),
                    title: transaction.title ?? "",
                    categoryName: transaction.category?.wrappedName ?? "",
                    paymentModeName: transaction.paymentMode?.wrappedName ?? "",
                    goalName: transaction.goal?.wrappedName ?? "",
                    occurredAt: transaction.occurredAt ?? .now,
                    notes: transaction.notes ?? ""
                ),
                title: "Edit Transaction",
                goalOptions: viewModel.goalOptions
            ) { draft in
                if viewModel.saveTransaction(draft: draft, editing: transaction) {
                    editingTransaction = nil
                    return true
                }
                return false
            }
        }
        .sheet(isPresented: $showingReport) {
            NavigationStack {
                ReportView(book: viewModel.book, detailViewModel: viewModel)
            }
        }
        .sheet(item: $viewingTransaction) { transaction in
            NavigationStack {
                TransactionDetailView(
                    transaction: transaction,
                    onEdit: {
                        viewingTransaction = nil
                        editingTransaction = transaction
                    },
                    onDelete: {
                        viewModel.deleteTransaction(transaction)
                        viewingTransaction = nil
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { shareURL != nil },
            set: { if $0 == false { shareURL = nil } }
        )) {
            if let shareURL {
                ActivityView(items: [shareURL])
            }
        }
        .sheet(isPresented: $isShowingBookEditor) {
            BookFormView(
                title: "Edit Book",
                initialName: viewModel.book.name ?? "",
                initialOwnerName: viewModel.book.ownerName ?? "You"
            ) { name, ownerName in
                viewModel.book.name = name
                viewModel.book.ownerName = ownerName
                viewModel.book.updatedAt = .now
                try? context.saveIfNeeded()
            }
        }
        .sheet(isPresented: $isShowingPDFPicker) {
            PDFDocumentPicker { url in
                viewModel.preparePDFImport(from: url)
                isShowingPDFPicker = false
            }
        }
        .sheet(item: Binding(
            get: { viewModel.importPreview.map(ImportPreviewSheetItem.init(preview:)) },
            set: { _ in viewModel.importPreview = nil }
        )) { item in
            PDFImportPreviewView(preview: item.preview) {
                viewModel.commitImportPreview()
            }
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { viewModel.errorMessage != nil || reportViewModel.errorMessage != nil },
            set: { _ in
                viewModel.errorMessage = nil
                reportViewModel.errorMessage = nil
            }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? reportViewModel.errorMessage ?? "")
        }
    }
}

private struct BookDetailContent: View {
    @ObservedObject var viewModel: BookDetailViewModel
    let onShowReport: () -> Void
    let onCashIn: () -> Void
    let onCashOut: () -> Void
    let onEditTransaction: (TransactionEntry) -> Void
    let onDeleteTransaction: (TransactionEntry) -> Void
    let onOpenTransaction: (TransactionEntry) -> Void
    let onExportPDF: () -> Void
    let onEditBook: () -> Void
    let onImportPDF: () -> Void
    let onShareReport: () -> Void
    let onBack: () -> Void
    let onDeleteBook: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()
            ScrollView { content }
        }
        .safeAreaInset(edge: .bottom) { bottomBar }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let isBackSwipe = value.startLocation.x < 40 && value.translation.width > 90 && abs(value.translation.height) < 80
                    if isBackSwipe {
                        onBack()
                    }
                }
        )
    }

    private func actionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            topHeader
                .padding(.horizontal)
            FilterBarView(
                filter: Binding(
                    get: { viewModel.filter },
                    set: { viewModel.filter = $0 }
                ),
                categoryOptions: viewModel.categoryOptions,
                paymentModeOptions: viewModel.paymentModeOptions
            )

            headerStrip

            SummaryCardView(
                balance: viewModel.netBalance,
                cashIn: viewModel.totalCashIn,
                cashOut: viewModel.totalCashOut
            ) { onShowReport() }
            .padding(.horizontal)

            if viewModel.groupedTransactions.isEmpty {
                EmptyStateView(
                    title: "No Transactions",
                    message: "Add a cash in or cash out entry to populate this book.",
                    systemImage: "tray"
                )
                .padding(.horizontal)
            } else {
                transactionsSection
            }
        }
        .padding(.top)
    }

    private var topHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onBack()
            } label: {
                headerIcon(systemImage: "chevron.left")
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 6) {
                Text(viewModel.book.name ?? "Book")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("Filtered Ledger")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 10) {
                Button(action: onExportPDF) {
                    headerIcon(systemImage: "arrow.down.doc")
                }
                .buttonStyle(.plain)

                Menu {
                    Button("Edit Book", action: onEditBook)
                    Button("Import PDF Statement", action: onImportPDF)
                    Button("Share Report", action: onShareReport)
                    Button("Delete Book", role: .destructive, action: onDeleteBook)
                } label: {
                    headerIcon(systemImage: "ellipsis")
                }
            }
        }
    }

    private var headerStrip: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(viewModel.filteredTransactions.count) entries")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
            Spacer()
            Image(systemName: "calendar.badge.clock")
                .font(.title2)
                .foregroundStyle(AppTheme.accent)
        }
        .padding(18)
        .appCardStyle(cornerRadius: 22)
        .padding(.horizontal)
    }

    private var transactionsSection: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.groupedTransactions, id: \.date) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppFormatters.sectionDate.string(from: group.date))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                        .padding(.horizontal)

                    ForEach(group.entries, id: \.objectID) { transaction in
                        Button {
                            onOpenTransaction(transaction)
                        } label: {
                            TransactionRowCard(transaction: transaction)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.bottom, 88)
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            actionButton(title: "Cash In", systemImage: "arrow.down.circle.fill", tint: .green, action: onCashIn)
            actionButton(title: "Cash Out", systemImage: "arrow.up.circle.fill", tint: .red, action: onCashOut)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(.ultraThinMaterial.opacity(0.95))
    }

    private func headerIcon(systemImage: String) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(AppTheme.cardFill)
            .frame(width: 46, height: 46)
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            }
            .overlay {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
            }
    }
}

private struct ImportPreviewSheetItem: Identifiable {
    let id = UUID()
    let preview: StatementImportPreview
}
