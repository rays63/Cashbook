import CoreData
import SwiftUI

struct GoalsHomeView: View {
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \GoalEntity.updatedAt, ascending: false)],
        animation: .smooth
    )
    private var goals: FetchedResults<GoalEntity>

    @State private var isShowingGoalForm = false
    @State private var editingGoal: GoalEntity?
    @State private var errorMessage: String?
    @State private var searchText = ""
    @State private var selectedFilter: GoalStatusFilter = .active

    private var filteredGoals: [GoalEntity] {
        goals.filter { goal in
            let matchesSearch = searchText.isEmpty ||
                goal.wrappedName.localizedCaseInsensitiveContains(searchText) ||
                (goal.book?.name ?? "").localizedCaseInsensitiveContains(searchText)

            let matchesFilter: Bool
            switch selectedFilter {
            case .active:
                matchesFilter = goal.progressRatio < 1
            case .completed:
                matchesFilter = goal.progressRatio >= 1
            case .all:
                matchesFilter = true
            }

            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        header
                        heroCard
                        controlsCard
                        summaryStrip
                        goalList
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $isShowingGoalForm) {
                GoalFormView(title: "Add Goal", initialDraft: GoalDraft()) { draft in
                    do {
                        try GoalService.createGoal(from: draft, in: context)
                        return true
                    } catch {
                        errorMessage = error.localizedDescription
                        return false
                    }
                }
            }
            .sheet(item: $editingGoal) { goal in
                GoalFormView(
                    title: "Edit Goal",
                    initialDraft: GoalDraft(
                        name: goal.wrappedName,
                        budgetText: String(format: "%.2f", goal.targetAmount),
                        hasDeadline: goal.deadline != nil,
                        deadline: goal.deadline ?? .now
                    )
                ) { draft in
                    do {
                        try GoalService.updateGoal(goal, from: draft, in: context)
                        editingGoal = nil
                        return true
                    } catch {
                        errorMessage = error.localizedDescription
                        return false
                    }
                }
            }
            .alert("Unable to save goal", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if $0 == false { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Dream Goals")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                Text("Turn dreams into achievable goals")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
            }

            Spacer()

            Button {
                isShowingGoalForm = true
            } label: {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.cardFill)
                    .frame(width: 46, height: 46)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    }
                    .overlay {
                        Image(systemName: "plus")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryText)
                    }
            }
            .buttonStyle(.plain)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Set targets and watch your progress every day")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)

            Text("Create savings goals, assign your cash in entries, and see exactly how much you have saved and what remains.")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                statBubble(title: "Goals", value: "\(goals.count)")
                statBubble(title: "Active", value: "\(goals.filter { $0.progressRatio < 1 }.count)")
                statBubble(title: "Done", value: "\(goals.filter { $0.progressRatio >= 1 }.count)")
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    Color(uiColor: .systemBackground).opacity(0.96),
                    AppTheme.cardFill
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 32, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow.opacity(0.9), radius: 20, x: 0, y: 12)
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.secondaryText)

                TextField("Search goals...", text: $searchText)
                    .foregroundStyle(AppTheme.primaryText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.listRowFill, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            HStack(spacing: 10) {
                ForEach(GoalStatusFilter.allCases) { filter in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filter.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(selectedFilter == filter ? .white : AppTheme.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(selectedFilter == filter ? AppTheme.accent : AppTheme.accentSoft)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .appCardStyle(cornerRadius: 26)
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            miniSummary(
                title: "Saved",
                value: AppFormatters.currencyString(for: filteredGoals.reduce(0) { $0 + $1.currentProgress }),
                tint: AppTheme.success
            )
            miniSummary(
                title: "Remaining",
                value: AppFormatters.currencyString(for: filteredGoals.reduce(0) { $0 + max($1.targetAmount - $1.currentProgress, 0) }),
                tint: .orange
            )
        }
    }

    private var goalList: some View {
        VStack(alignment: .leading, spacing: 14) {
            if filteredGoals.isEmpty {
                EmptyStateView(
                    title: goals.isEmpty ? "No goals yet" : "No matching goals",
                    message: goals.isEmpty ? "Add a goal and start assigning cash in transactions from any book to watch progress grow." : "Try a different search or filter to see your goals.",
                    systemImage: "flag.checkered"
                )
            } else {
                ForEach(filteredGoals, id: \.objectID) { goal in
                    goalCard(for: goal)
                }
            }
        }
    }

    private func goalCard(for goal: GoalEntity) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(goalAccent(for: goal).opacity(0.14))
                        .frame(width: 62, height: 62)
                    Image(systemName: goalSymbol(for: goal))
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(goalAccent(for: goal))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.wrappedName)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.primaryText)

                    HStack(spacing: 6) {
                        Image(systemName: goal.progressRatio >= 1 ? "checkmark.circle.fill" : "clock")
                        Text(goal.progressRatio >= 1 ? "Completed" : "In Progress")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(goal.progressRatio >= 1 ? AppTheme.success : AppTheme.secondaryText)

                    if let bookName = goal.book?.name, bookName.isEmpty == false {
                        Text(bookName)
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                Spacer()
            }

            HStack(spacing: 18) {
                metricBlock(title: "Saved", value: AppFormatters.currencyString(for: goal.currentProgress), tint: AppTheme.success)
                metricBlock(title: "Remaining", value: AppFormatters.currencyString(for: max(goal.targetAmount - goal.currentProgress, 0)), tint: goalAccent(for: goal))
                metricBlock(title: "Target", value: AppFormatters.currencyString(for: goal.targetAmount), tint: AppTheme.primaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(goal.progressRatio * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(goalAccent(for: goal))
                    Spacer()
                    if let deadline = goal.deadline {
                        Text("Due \(AppFormatters.shortDate.string(from: deadline))")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }

                ProgressView(value: goal.progressRatio)
                    .tint(goalAccent(for: goal))
                    .scaleEffect(x: 1, y: 1.35, anchor: .center)
            }

            Button {
                editingGoal = goal
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(goalAccent(for: goal))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        goalAccent(for: goal).opacity(0.10),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.cardFill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(goalAccent(for: goal).opacity(0.18), lineWidth: 1)
        )
        .shadow(color: AppTheme.shadow.opacity(0.85), radius: 18, x: 0, y: 10)
    }

    private func statBubble(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(AppTheme.listRowFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func miniSummary(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appCardStyle(cornerRadius: 22)
    }

    private func metricBlock(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func goalSymbol(for goal: GoalEntity) -> String {
        let name = goal.wrappedName.lowercased()
        if name.contains("trip") || name.contains("travel") { return "airplane" }
        if name.contains("car") || name.contains("bike") { return "car.fill" }
        if name.contains("home") || name.contains("house") { return "house.fill" }
        if name.contains("ps") || name.contains("game") { return "gamecontroller.fill" }
        if name.contains("phone") || name.contains("ipad") || name.contains("laptop") { return "iphone.gen3" }
        if name.contains("fund") || name.contains("save") || name.contains("emergency") { return "banknote.fill" }
        return "star.fill"
    }

    private func goalAccent(for goal: GoalEntity) -> Color {
        let name = goal.wrappedName.lowercased()
        if name.contains("trip") || name.contains("travel") { return .orange }
        if name.contains("ps") || name.contains("game") { return .blue }
        if name.contains("fund") || name.contains("save") || name.contains("emergency") { return AppTheme.success }
        if name.contains("home") { return .purple }
        return AppTheme.accent
    }
}

private enum GoalStatusFilter: String, CaseIterable, Identifiable {
    case active
    case completed
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .active: "Active"
        case .completed: "Done"
        case .all: "All"
        }
    }
}
