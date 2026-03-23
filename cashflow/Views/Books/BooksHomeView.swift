import CoreData
import SwiftUI

struct BooksHomeView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = BooksListViewModel()
    @State private var isPresentingBookForm = false
    @State private var editingBook: BookEntity?

    var body: some View {
        NavigationStack {
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
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(viewModel.filteredBooks, id: \.objectID) { book in
                            NavigationLink {
                                BookDetailView(book: book, deleteAction: {
                                    viewModel.deleteBook(book)
                                })
                            } label: {
                                BookRowCard(book: book)
                                    .padding(.vertical, 4)
                            }
                            .swipeActions {
                                Button("Edit") {
                                    editingBook = book
                                }
                                .tint(.blue)

                                Button("Delete", role: .destructive) {
                                    viewModel.deleteBook(book)
                                }
                            }
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: viewModel.deleteBooks)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("CashBook Pro")
            .searchable(text: $viewModel.searchText, prompt: "Search books")
            .toolbar {
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingBookForm = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
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
