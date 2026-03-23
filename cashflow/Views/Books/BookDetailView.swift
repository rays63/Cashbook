import CoreData
import SwiftUI

struct BookDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var exportSettings: ExportSettingsStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BookDetailViewModel
    @StateObject private var reportViewModel = ReportViewModel()

    @State private var isShowingTransactionForm = false
    @State private var selectedKind: TransactionKind = .cashIn
    @State private var editingTransaction: TransactionEntry?
    @State private var showingReport = false
    @State private var shareURL: URL?
    @State private var isShowingBookEditor = false

    let deleteAction: () -> Void

    init(book: BookEntity, deleteAction: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: BookDetailViewModel(book: book))
        self.deleteAction = deleteAction
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
            onExportPDF: {
                let snapshot = viewModel.reportSnapshot(for: .allEntries)
                reportViewModel.export(book: viewModel.book, snapshot: snapshot, fields: exportSettings.orderedFields(), asPDF: true)
                shareURL = reportViewModel.exportedURL
            },
            onEditBook: { isShowingBookEditor = true },
            onShareReport: {
                let snapshot = viewModel.reportSnapshot(for: .allEntries)
                reportViewModel.export(book: viewModel.book, snapshot: snapshot, fields: exportSettings.orderedFields(), asPDF: true)
                shareURL = reportViewModel.exportedURL
            },
            onDeleteBook: {
                deleteAction()
                dismiss()
            }
        )
        .task {
            viewModel.configure(context: context)
        }
        .sheet(isPresented: $isShowingTransactionForm) {
            TransactionFormView(
                book: viewModel.book,
                initialDraft: TransactionDraft(type: selectedKind),
                title: selectedKind.title
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
                    occurredAt: transaction.occurredAt ?? .now,
                    notes: transaction.notes ?? ""
                ),
                title: "Edit Transaction"
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
    let onExportPDF: () -> Void
    let onEditBook: () -> Void
    let onShareReport: () -> Void
    let onDeleteBook: () -> Void

    var body: some View {
        ScrollView { content }
            .navigationTitle(viewModel.book.name ?? "Book")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) { bottomBar }
            .toolbar { toolbarContent }
    }

    private func actionButton(title: String, systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 20) {
            FilterBarView(
                filter: Binding(
                    get: { viewModel.filter },
                    set: { viewModel.filter = $0 }
                ),
                categoryOptions: viewModel.categoryOptions,
                paymentModeOptions: viewModel.paymentModeOptions
            )

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

    private var transactionsSection: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(viewModel.groupedTransactions, id: \.date) { group in
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppFormatters.sectionDate.string(from: group.date))
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(group.entries, id: \.objectID) { transaction in
                        NavigationLink {
                            TransactionDetailView(
                                transaction: transaction,
                                onEdit: { onEditTransaction(transaction) },
                                onDelete: { onDeleteTransaction(transaction) }
                            )
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
        .padding()
        .background(.ultraThinMaterial)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: onExportPDF) {
                Image(systemName: "arrow.down.doc")
            }

            Menu {
                Button("Edit Book", action: onEditBook)
                Button("Share Report", action: onShareReport)
                Button("Delete Book", role: .destructive, action: onDeleteBook)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}
