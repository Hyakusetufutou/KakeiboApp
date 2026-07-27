//
//  RecurringTransactionEntity+CoreDataProperties.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/07/27
//
//
//

public import Foundation
public import CoreData

public typealias RecurringTransactionEntityCoreDataPropertiesSet = NSSet

extension RecurringTransactionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecurringTransactionEntity> {
        return NSFetchRequest<RecurringTransactionEntity>(entityName: "RecurringTransactionEntity")
    }

    @NSManaged public var amount: Double
    @NSManaged public var endDate: Date
    @NSManaged public var frequency: String
    @NSManaged public var id: UUID
    @NSManaged public var startDate: Date
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var category: CategoryEntity
    @NSManaged public var transactions: NSSet?

}

// MARK: Generated accessors for transactions
extension RecurringTransactionEntity {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: TransactionEntity)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: TransactionEntity)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension RecurringTransactionEntity: Identifiable {

}
