//
//  TransactionLog+CoreDataProperties.swift
//  
//
//  Created by Raymond Maharjan on 24/03/2026.
//
//  This file was automatically generated and should not be edited.
//

public import Foundation
public import CoreData


public typealias TransactionLogCoreDataPropertiesSet = NSSet

extension TransactionLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionLog> {
        return NSFetchRequest<TransactionLog>(entityName: "TransactionLog")
    }

    @NSManaged public var action: String?
    @NSManaged public var details: String?
    @NSManaged public var id: UUID?
    @NSManaged public var timestamp: Date?
    @NSManaged public var transaction: TransactionEntry?

}

extension TransactionLog : Identifiable {

}
