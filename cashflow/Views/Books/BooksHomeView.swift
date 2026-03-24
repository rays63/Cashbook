import CoreData
import SwiftUI

struct BooksHomeView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = BooksListViewModel()
    @State private var isPresentingBookForm = false
    @State private var editingBook: BookEntity?
    @State private var isShowingAppearanceSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Group {
                    if viewModel.filteredBooks.isEmpty {
                        VStack(spacing: 20) {
                            EmptyStateView(
                                title: viewModel.searchText.isEmpty ? "No Books Yet" : "No Matching Books",
                                message: viewModel.searchText.isEmpty ? "Create your first cash book to start tracking daily income and expenses." : "Try a different search term or sort option.",
                                systemImage: "books.vertical"
                            )

                            if viewModel.searchText.isEmpty {
                                Button("Add New Book") {
                                    isPresentingBookForm = true
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(AppTheme.accent)
                            }
                        }
                        .padding()
                    } else {
                        List {
                            Section {
                                ForEach(viewModel.filteredBooks, id: \.objectID) { book in
                                    NavigationLink {
                                        BookDetailView(book: book, deleteAction: {
                                            viewModel.deleteBook(book)
                                        })
                                    } label: {
                                        BookRowCard(book: book)
                                            .padding(.vertical, 6)
                                    }
                                    .swipeActions {
                                        Button("Edit") {
                                            editingBook = book
                                        }
                                        .tint(AppTheme.accent)

                                        Button("Delete", role: .destructive) {
                                            viewModel.deleteBook(book)
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete(perform: viewModel.deleteBooks)
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search books")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CashBook Pro")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryText)
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort By", selection: $viewModel.sortOption) {
                            ForEach(BookSortOption.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down.circle")
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        isShowingAppearanceSettings = true
                    } label: {
                        Image(systemName: "paintbrush")
                            .foregroundStyle(AppTheme.primaryText)
                    }

                    Button {
                        isPresentingBookForm = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(AppTheme.primaryText)
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                viewModel.configure(context: context)
            }
            .sheet(isPresented: $isPresentingBookForm) {
                BookFormView(
                    title: "New Book",
                    initialName: "",
                    initialOwnerName: "You"
                ) { name, ownerName in
                    viewModel.createBook(name: name, ownerName: ownerName)
                }
            }
            .sheet(item: $editingBook) { book in
                BookFormView(
                    title: "Edit Book",
                    initialName: book.name ?? "",
                    initialOwnerName: book.ownerName ?? "You"
                ) { name, ownerName in
                    viewModel.updateBook(book, name: name, ownerName: ownerName)
                }
            }
            .sheet(isPresented: $isShowingAppearanceSettings) {
                NavigationStack {
                    AppearanceSettingsView()
                }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.dismissError() }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}
