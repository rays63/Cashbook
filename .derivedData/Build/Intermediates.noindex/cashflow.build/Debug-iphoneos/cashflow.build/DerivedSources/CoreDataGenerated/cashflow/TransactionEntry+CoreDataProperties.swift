//
//  TransactionEntry+CoreDataProperties.swift
//  
//
//  Created by Raymond Maharjan on 24/03/2026.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias TransactionEntryCoreDataPropertiesSet = NSSet

extension TransactionEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionEntry> {
        return NSFetchRequest<TransactionEntry>(entityName: "TransactionEntry")
    }

    @NSManaged public var amount: Double
    @NSManaged public var createdAt: Date?
    @NSManaged public var editorName: String?
    @NSManaged public var id: UUID?
    @NSManaged public var notes: String?
    @NSManaged public var occurredAt: Date?
    @NSManaged public var runningBalance: Double
    @NSManaged public var title: String?
    @NSManaged public var typeRaw: Int16
    @NSManaged public var updatedAt: Date?
    @NSManaged public var book: BookEntity?
    @NSManaged public var category: CategoryEntity?
    @NSManaged public var logs: NSSet?
    @NSManaged public var paymentMode: PaymentModeEntity?

}

// MARK: Generated accessors for logs
extension TransactionEntry {

    @objc(addLogsObject:)
    @NSManaged public func addToLogs(_ value: TransactionLog)

    @objc(removeLogsObject:)
    @NSManaged public func removeFromLogs(_ value: TransactionLog)

    @objc(addLogs:)
    @NSManaged public func addToLogs(_ values: NSSet)

    @objc(removeLogs:)
    @NSManaged public func removeFromLogs(_ values: NSSet)

}

extension TransactionEntry : Identifiable {

}
