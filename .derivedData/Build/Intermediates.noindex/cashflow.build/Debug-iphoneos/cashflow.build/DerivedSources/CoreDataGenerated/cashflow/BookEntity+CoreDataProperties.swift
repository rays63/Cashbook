//
//  BookEntity+CoreDataProperties.swift
//  
//
//  Created by Raymond Maharjan on 24/03/2026.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias BookEntityCoreDataPropertiesSet = NSSet

extension BookEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BookEntity> {
        return NSFetchRequest<BookEntity>(entityName: "BookEntity")
    }

    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var ownerName: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var categories: NSSet?
    @NSManaged public var paymentModes: NSSet?
    @NSManaged public var transactions: NSSet?

}

// MARK: Generated accessors for categories
extension BookEntity {

    @objc(addCategoriesObject:)
    @NSManaged public func addToCategories(_ value: CategoryEntity)

    @objc(removeCategoriesObject:)
    @NSManaged public func removeFromCategories(_ value: CategoryEntity)

    @objc(addCategories:)
    @NSManaged public func addToCategories(_ values: NSSet)

    @objc(removeCategories:)
    @NSManaged public func removeFromCategories(_ values: NSSet)

}

// MARK: Generated accessors for paymentModes
extension BookEntity {

    @objc(addPaymentModesObject:)
    @NSManaged public func addToPaymentModes(_ value: PaymentModeEntity)

    @objc(removePaymentModesObject:)
    @NSManaged public func removeFromPaymentModes(_ value: PaymentModeEntity)

    @objc(addPaymentModes:)
    @NSManaged public func addToPaymentModes(_ values: NSSet)

    @objc(removePaymentModes:)
    @NSManaged public func removeFromPaymentModes(_ values: NSSet)

}

// MARK: Generated accessors for transactions
extension BookEntity {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: TransactionEntry)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: TransactionEntry)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension BookEntity : Identifiable {

}
