import CoreData
import SwiftUI

struct BooksHomeView: View {
    @Environment(\.managedObjectContext) private var context
    @StateObject private var viewModel = BooksListViewModel()
    @State private var isPresentingBookForm = false
    @State private var editingBook: BookEntity?
    @State private var selectedBook: BookEntity?

    var body: some View {
        ZStack {
            AppBackgroundView()

            if let selectedBook {
                BookDetailView(
                    book: selectedBook,
                    deleteAction: {
                        viewModel.deleteBook(selectedBook)
                        self.selectedBook = nil
                    },
                    onBack: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            self.selectedBook = nil
                        }
                    }
                )
                .id(selectedBook.objectID)
                .transition(.move(edge: .trailing))
            } else {
                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 10)

                    searchBar
                        .padding(.horizontal, 20)
                        .padding(.bottom, 12)

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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            Section {
                                ForEach(viewModel.filteredBooks, id: \.objectID) { book in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.22)) {
                                            selectedBook = book
                                        }
                                    } label: {
                                        BookRowCard(book: book)
                                            .padding(.vertical, 2)
                                    }
                                    .buttonStyle(.plain)
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
        }
        .task {
            viewModel.configure(context: context)
        }
        .sheet(isPresented: $isPresentingBookForm) {
            BookFormView(
                title: "New Book",
                initialName: "",
                initialDescription: ""
            ) { name, description in
                viewModel.createBook(name: name, description: description)
            }
        }
        .sheet(item: $editingBook) { book in
            BookFormView(
                title: "Edit Book",
                initialName: book.name ?? "",
                initialDescription: book.ownerName ?? ""
            ) { name, description in
                viewModel.updateBook(book, name: name, description: description)
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

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Books")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("Manage your cashbooks")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()

            Button {
                isPresentingBookForm = true
            } label: {
                headerIcon(systemImage: "plus")
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)

            TextField("Search books", text: $viewModel.searchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .foregroundStyle(AppTheme.primaryText)

            if viewModel.searchText.isEmpty == false {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
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
