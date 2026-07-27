//
//  TransactionEntity+CoreDataProperties.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/07/27
//
//
//

public import Foundation
public import CoreData

public typealias TransactionEntityCoreDataPropertiesSet = NSSet

extension TransactionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TransactionEntity> {
        return NSFetchRequest<TransactionEntity>(entityName: "TransactionEntity")
    }

    @NSManaged public var amount: NSDecimalNumber
    @NSManaged public var createdAt: Date
    @NSManaged public var date: Date
    @NSManaged public var id: UUID
    @NSManaged public var memo: String
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var category: CategoryEntity
    @NSManaged public var recurringTransaction: RecurringTransactionEntity?

}

extension TransactionEntity: Identifiable {

}
