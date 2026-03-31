import CoreData
import Foundation

enum GoalServiceError: LocalizedError {
    case emptyName
    case invalidBudget
    case duplicateName

    var errorDescription: String? {
        switch self {
        case .emptyName:
            "Goal name cannot be empty."
        case .invalidBudget:
            "Enter a budget greater than zero."
        case .duplicateName:
            "A goal with that name already exists."
        }
    }
}

enum GoalService {
    @discardableResult
    static func createGoal(from draft: GoalDraft, in context: NSManagedObjectContext) throws -> GoalEntity {
        let validated = try validate(draft: draft, in: context, excluding: nil)

        let goal = GoalEntity(context: context)
        goal.id = UUID()
        goal.name = validated.name
        goal.targetAmount = validated.budget
        goal.deadline = validated.deadline
        goal.createdAt = .now
        goal.updatedAt = .now
        try context.saveIfNeeded()
        return goal
    }

    static func updateGoal(_ goal: GoalEntity, from draft: GoalDraft, in context: NSManagedObjectContext) throws {
        let validated = try validate(draft: draft, in: context, excluding: goal)

        goal.name = validated.name
        goal.targetAmount = validated.budget
        goal.deadline = validated.deadline
        goal.updatedAt = .now
        try context.saveIfNeeded()
    }

    static func deleteGoal(_ goal: GoalEntity, in context: NSManagedObjectContext) throws {
        context.delete(goal)
        try context.saveIfNeeded()
    }

    private static func validate(draft: GoalDraft, in context: NSManagedObjectContext, excluding goal: GoalEntity?) throws -> (name: String, budget: Double, deadline: Date?) {
        let trimmedName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.isEmpty == false else {
            throw GoalServiceError.emptyName
        }

        guard let budget = draft.budgetValue, budget > 0 else {
            throw GoalServiceError.invalidBudget
        }

        let request = GoalEntity.fetchRequest()
        let goals = (try? context.fetch(request)) ?? []
        let hasDuplicate = goals.contains { existing in
            existing != goal && existing.wrappedName.caseInsensitiveCompare(trimmedName) == .orderedSame
        }
        guard hasDuplicate == false else {
            throw GoalServiceError.duplicateName
        }

        return (trimmedName, budget, draft.hasDeadline ? draft.deadline : nil)
    }
}
