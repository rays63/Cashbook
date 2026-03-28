# CashBook Pro

A local-first personal finance and cash ledger app for iOS that helps users manage multiple books, record transactions, import statement data, track goals, and generate reports.

This project is open source and available under the MIT License.

## Features

- **Multi-Book Management**: Create and manage separate books for different financial contexts (personal, business, etc.)
- **Transaction Tracking**: Record cash in and cash out transactions with categories, payment modes, and notes
- **Statement Import**: Import transactions from PDF bank statements and XLS wallet files with preview and duplicate detection
- **Financial Reports**: Generate and export reports (all entries, day-wise, category-wise, payment mode) to PDF or spreadsheet
- **Analytics Dashboard**: Visual insights into income, spending, and cash flow trends
- **Goals Tracking**: Set savings goals and track progress with visual progress bars
- **Calendar Overview**: Date-based view of financial activity
- **Appearance Settings**: Support for light, dark, and system appearance modes
- **Local-First Design**: All data stored locally on device, no cloud dependency

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/cashflow.git
   cd cashflow
   ```

2. Open the project in Xcode:
   ```bash
   open cashflow.xcodeproj
   ```

3. Build and run the app on your iOS device or simulator.

## Architecture

- **Framework**: SwiftUI
- **Architecture Pattern**: MVVM (Model-View-ViewModel)
- **Persistence**: Core Data
- **Import/Export**: Custom services for PDF and XLS parsing
- **Navigation**: SwiftUI NavigationStack

## Project Structure

```
cashflow/
├── cashflowApp.swift          # App entry point
├── ContentView.swift          # Main content view
├── Info.plist                 # App configuration
├── Assets.xcassets/           # App assets and icons
├── cashflow.xcdatamodeld/     # Core Data model
├── Components/                # Reusable SwiftUI components
├── Extensions/                # Swift extensions and helpers
├── Models/                    # Data models and types
├── Resources/                 # Static resources (JS for XLS parsing)
├── Services/                  # Business logic and data services
├── ViewModels/                # MVVM view models
└── Views/                     # SwiftUI views organized by feature
```

## Usage

1. **Getting Started**: Create your first book from the home dashboard
2. **Adding Transactions**: Use the quick add buttons for cash in/out or the detailed form
3. **Importing Statements**: Navigate to a book's detail view and use the import options for PDF or XLS files
4. **Viewing Reports**: Access the Reports tab for analytics and export options
5. **Managing Goals**: Create and track savings goals in the Goals section

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and Core Data
- XLS parsing powered by SheetJS (xlsx library)
- PDF text extraction using PDFKit
