//
//  CategoryEntity+CoreDataProperties.swift
//  
//
//  Created by Raymond Maharjan on 24/03/2026.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias CategoryEntityCoreDataPropertiesSet = NSSet

extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var colorHex: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var icon: String?
    @NSManaged public var id: UUID?
    @NSManaged public var isSystem: Bool
    @NSManaged public var name: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var book: BookEntity?
    @NSManaged public var transactions: NSSet?

}

// MARK: Generated accessors for transactions
extension CategoryEntity {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: TransactionEntry)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: TransactionEntry)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension CategoryEntity : Identifiable {

}
