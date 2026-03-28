# CashBook Pro Product Requirements Document

## Document Control
- Product: CashBook Pro
- Platform: iOS
- Framework: SwiftUI
- Architecture: MVVM with Core Data
- Document Version: 1.0
- Last Updated: March 28, 2026
- Status: Active

## 1. Executive Summary
CashBook Pro is a local-first personal finance and cash ledger app for iOS that helps users manage multiple books, record cash in and cash out transactions, import statement data, track goals, and generate reports. The product is designed to give users a fast, clean, and reliable way to manage day-to-day finances from a mobile device without depending on cloud connectivity.

The app focuses on three core outcomes:
- make bookkeeping simple and fast
- improve visibility into balances, income, and spending
- reduce manual work through statement import and export tools

## 2. Problem Statement
Many users track cash flow using paper notes, messaging apps, spreadsheets, or fragmented finance tools. These workflows create recurring problems:
- balances are hard to maintain accurately
- data is split across multiple personal or business contexts
- statement data must be entered manually
- duplicate entries are common after re-importing statements
- reports are difficult to generate quickly
- savings goals are tracked outside the bookkeeping workflow

CashBook Pro addresses these pain points by providing a structured, mobile-first ledger app with multiple books, transaction management, reporting, analytics, and statement import support.

## 3. Product Vision
Build a polished iOS bookkeeping app that feels simple enough for daily use while being powerful enough to replace ad hoc spreadsheets and notes for personal and small-scale financial tracking.

## 4. Product Goals
- Enable users to manage multiple independent books from one app.
- Make transaction entry, editing, and tracking fast and intuitive.
- Support statement import from PDF and XLS files with preview before saving.
- Prevent duplicate imports from repeated statements.
- Provide meaningful reports and visual financial insights.
- Help users track savings goals with live progress updates.
- Maintain a premium, minimal, and theme-aware iOS experience.

## 5. Non-Goals
The following are explicitly outside the initial scope:
- cloud sync or account-based backup
- multi-user collaboration
- live bank integrations
- OCR for scanned, image-only statements
- investment portfolio management
- loan, credit, or debt repayment planning
- automation or recurring import scheduling

## 6. Target Users
### Primary Users
- individuals tracking daily personal finances
- freelancers managing cash flow manually
- small shop owners or side-business operators
- users who maintain separate books for different purposes

### Secondary Users
- users importing wallet or bank statements from local financial providers
- users who need lightweight reporting and export for recordkeeping

## 7. User Needs
- I need to keep separate books for different contexts.
- I need to see current balance quickly.
- I need to add transactions without friction.
- I need categories and payment modes to stay organized.
- I need to import statement data instead of entering everything manually.
- I need imports to avoid creating duplicates.
- I need to export reports for sharing or archiving.
- I need a simple way to track progress toward savings goals.

## 8. Product Scope
### In Scope
- multi-book ledger management
- transaction creation, editing, deletion, and logs
- category and payment mode management
- PDF statement import
- XLS statement import
- duplicate detection for imports
- report generation and export
- analytics dashboard in reports tab
- goals tracking
- calendar overview
- settings and appearance control

### Out of Scope
- online account registration
- shared books between users
- auto-sync from bank APIs
- desktop or web clients

## 9. Feature Requirements

### 9.1 Home Dashboard
The home screen acts as the high-level entry point into the app.

Requirements:
- Show a top-level dashboard experience.
- Display recently updated books.
- Allow navigation into book details.
- Provide access to the books list.
- Surface financial context at a glance through summary content.

Success condition:
- User can open the app and immediately understand recent activity and where to continue.

### 9.2 Books List
The books screen is the main management surface for all books.

Requirements:
- Display all books.
- Show book name, balance, and last updated date.
- Allow users to add a new book.
- Support search.
- Allow opening a selected book.
- Allow editing and deleting books.

Success condition:
- User can create and manage multiple books without confusion.

### 9.3 Book Detail
The book detail screen is the primary working ledger view.

Requirements:
- Show current book title and actions.
- Show filters for:
  - date
  - entry type
  - category
  - payment mode
- Show summary card with:
  - net balance
  - total cash in
  - total cash out
- Group entries by date.
- Show running balance on entries.
- Support quick creation of cash in and cash out.
- Provide access to reporting and statement imports.

Success condition:
- User can review, filter, and manage all entries in a book from one screen.

### 9.4 Transactions
Transactions are the core financial records in the system.

Requirements:
- User can create and edit transactions.
- Required fields:
  - amount
  - title
  - type
- Supported fields:
  - category
  - payment mode
  - date and time
  - notes
  - optional linked goal for cash in
- Saving must update balances immediately.
- Edits must be logged for history tracking.
- Transaction details view must show full information and edit log history.

Success condition:
- Transaction records remain clear, accurate, and auditable.

### 9.5 Category and Payment Mode Management
Users need lightweight catalog management from within the app.

Requirements:
- Category and payment mode inputs should use dropdown selection.
- Each dropdown should provide an edit/manage option.
- Users can add new options.
- Users can rename existing options.
- Changes must be reusable across transaction forms.

Success condition:
- Users can keep option lists clean without leaving the flow of data entry.

### 9.6 PDF Statement Import
The app must support importing transactions from PDF bank statements.

Requirements:
- Use document picker to select PDF files.
- Extract text using PDFKit.
- Parse transaction lines into app transaction format.
- Handle common line structures that include:
  - date
  - description
  - withdraw
  - deposit
  - balance
- Handle numeric values with commas.
- Ignore invalid rows.
- Show preview before saving.
- Show skipped line count.
- Save valid transactions into the selected book.

Success condition:
- User can import supported PDF statement files with minimal manual cleanup.

### 9.7 XLS Statement Import
The app must support importing legacy XLS wallet or statement files.

Requirements:
- Use document picker to select `.xls` files.
- Read worksheet data through a bundled XLS parser.
- Extract rows from the first sheet.
- Map statement columns into transaction fields.
- Preserve description text from the actual worksheet cells.
- Preserve reference code for each imported row.
- Show preview before saving.
- Save valid transactions into the selected book.

Success condition:
- User can import supported XLS statements and preserve meaningful titles and references.

### 9.8 Duplicate Detection
Imported statements must not create repeated entries when re-imported.

Requirements:
- Detect duplicates already موجود in the selected book.
- Detect duplicates repeated inside the same import file.
- Use a stable import signature based on:
  - normalized date
  - transaction type
  - amount
  - normalized title
  - statement balance when available
  - external reference when available
- Skip duplicates before save.
- Show duplicate count in preview.
- If every imported row is duplicate, show a clear message instead of saving nothing silently.

Success condition:
- Re-importing the same statement does not create duplicate transactions.

### 9.9 Reports
The app must provide both book-level reporting and export capabilities.

Requirements:
- Support report types:
  - all entries
  - day-wise
  - category-wise
  - payment mode
- Generate report snapshots from current filtered data.
- Support export to PDF.
- Support export to spreadsheet format.
- Allow users to choose export fields.

Success condition:
- Users can generate and share usable finance reports without external tools.

### 9.10 Reports Analytics Tab
The reports tab should act as a dashboard for visual insights.

Requirements:
- Provide financial insights across books or for a selected book.
- Support date-range filtering.
- Show summary metrics for:
  - income
  - spending
  - net cash flow
- Visualize trends and breakdowns.
- Show category and payment-mode summaries.

Success condition:
- Users can understand their financial patterns without reading raw tables only.

### 9.11 Goals
The goals feature helps users track savings progress.

Requirements:
- Users can create goals with:
  - name
  - target amount
  - optional deadline
- Show progress visually with:
  - saved amount
  - remaining amount
  - progress bar
- Goals should calculate across all books.
- Cash in transactions can optionally be assigned to a goal.
- Goal progress should update automatically when linked transactions are saved.

Success condition:
- Users can see progress toward a savings target without manual calculation.

### 9.12 Calendar
The calendar screen should provide a date-based overview of ledger activity.

Requirements:
- Show month-based calendar layout.
- Highlight days with transaction activity.
- Support day-level financial context.

Success condition:
- Users can quickly inspect when activity occurred over time.

### 9.13 Settings
The settings screen manages user preferences.

Requirements:
- Provide appearance selection:
  - follow system
  - light
  - dark
- Keep settings UI lightweight and easy to understand.

Success condition:
- Users can adjust app appearance in one place.

## 10. User Stories
- As a user, I want to create multiple books so I can track separate finances independently.
- As a user, I want to add cash in and cash out transactions quickly so that I can keep records up to date.
- As a user, I want filters on a book so I can narrow entries by type, category, payment mode, and date.
- As a user, I want to import statements from PDF and XLS so I do not have to type transactions manually.
- As a user, I want to preview imported data before saving so I can avoid bad imports.
- As a user, I want duplicate transactions to be skipped automatically so repeated imports do not pollute my books.
- As a user, I want reports and exports so I can review and share my records.
- As a user, I want to assign cash in to savings goals so I can track progress toward targets.
- As a user, I want dark mode and light mode support so the app feels comfortable in different environments.

## 11. Functional Requirements

### 11.1 Data Management
- All data must persist locally on device.
- Books, transactions, categories, payment modes, and logs must remain linked correctly.
- Running balances must be recalculated after any transaction mutation.

### 11.2 Validation
- Transaction amount must be greater than zero.
- Transaction title must not be empty.
- Import must reject unsupported or unreadable files with clear errors.

### 11.3 Import Handling
- The app must not save import rows without user confirmation.
- Invalid rows must not block valid rows from preview.
- Duplicate rows must be excluded before save.
- Reference code should be retained when available.

### 11.4 Export Handling
- Export output must respect field selection settings.
- PDF and spreadsheet export actions must provide shareable files.

## 12. Non-Functional Requirements
- App must function offline.
- UI should remain smooth on supported iPhones.
- App should support light and dark appearance.
- Error handling should be user friendly.
- Code should remain modular and maintainable.
- Parsing logic should be isolated from UI logic.

## 13. UX and Design Requirements
- UI should feel minimal, polished, and modern.
- Top-level navigation should be simple and consistent.
- Data-dense screens should remain readable.
- Import previews should clearly communicate:
  - rows ready to import
  - duplicates skipped
  - non-transaction lines skipped
- Empty states should guide the user toward the next action.
- Colors and typography should remain consistent across themes.

## 14. Technical Requirements
- SwiftUI for interface implementation
- MVVM for presentation architecture
- Core Data for local persistence
- NavigationStack or equivalent native-feeling navigation patterns
- Reusable SwiftUI components where practical
- Services layer for import/export logic

## 15. Success Metrics
- Users can create a first book in under one minute.
- Users can add a transaction in under fifteen seconds.
- Re-importing the same statement does not create duplicate entries.
- Report export succeeds reliably.
- Goal progress updates correctly after linked cash in transactions.
- Import errors are understandable and actionable.

## 16. Risks and Constraints
- Statement formats vary across banks and wallets.
- Legacy XLS parsing depends on worksheet format consistency.
- Duplicate logic may need tuning for new statement formats.
- Core Data schema evolution requires migration awareness.
- Export layouts may need refinement for broader use cases.

## 17. Future Enhancements
- cloud backup and sync
- recurring transactions
- CSV and XLSX import
- smarter bank-specific parsing rules
- category auto-classification
- budgeting by category
- reminders and notifications
- app lock with Face ID or passcode
- richer analytics and forecast views

## 18. Release Scope Summary
CashBook Pro v1 is intended to deliver:
- multi-book cashbook management
- transaction entry and edit history
- dropdown-based category and payment mode management
- PDF and XLS statement import
- duplicate-aware import flow
- report generation and export
- analytics dashboard
- goal tracking
- calendar overview
- appearance settings

This release should establish CashBook Pro as a reliable, local-first iOS bookkeeping product with strong everyday utility and a foundation for future expansion.
