//
//  CategoryEntity+CoreDataProperties.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/07/27
//
//
//

public import Foundation
public import CoreData

public typealias CategoryEntityCoreDataPropertiesSet = NSSet

extension CategoryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryEntity> {
        return NSFetchRequest<CategoryEntity>(entityName: "CategoryEntity")
    }

    @NSManaged public var color: String
    @NSManaged public var id: UUID
    @NSManaged public var isDefault: Bool
    @NSManaged public var name: String
    @NSManaged public var sortOrder: Int32
    @NSManaged public var type: String
    @NSManaged public var goals: NSSet?
    @NSManaged public var recurringTransactions: NSSet?
    @NSManaged public var transactions: NSSet?

}

// MARK: Generated accessors for goals
extension CategoryEntity {

    @objc(addGoalsObject:)
    @NSManaged public func addToGoals(_ value: GoalEntity)

    @objc(removeGoalsObject:)
    @NSManaged public func removeFromGoals(_ value: GoalEntity)

    @objc(addGoals:)
    @NSManaged public func addToGoals(_ values: NSSet)

    @objc(removeGoals:)
    @NSManaged public func removeFromGoals(_ values: NSSet)

}

// MARK: Generated accessors for recurringTransactions
extension CategoryEntity {

    @objc(addRecurringTransactionsObject:)
    @NSManaged public func addToRecurringTransactions(_ value: RecurringTransactionEntity)

    @objc(removeRecurringTransactionsObject:)
    @NSManaged public func removeFromRecurringTransactions(_ value: RecurringTransactionEntity)

    @objc(addRecurringTransactions:)
    @NSManaged public func addToRecurringTransactions(_ values: NSSet)

    @objc(removeRecurringTransactions:)
    @NSManaged public func removeFromRecurringTransactions(_ values: NSSet)

}

// MARK: Generated accessors for transactions
extension CategoryEntity {

    @objc(addTransactionsObject:)
    @NSManaged public func addToTransactions(_ value: TransactionEntity)

    @objc(removeTransactionsObject:)
    @NSManaged public func removeFromTransactions(_ value: TransactionEntity)

    @objc(addTransactions:)
    @NSManaged public func addToTransactions(_ values: NSSet)

    @objc(removeTransactions:)
    @NSManaged public func removeFromTransactions(_ values: NSSet)

}

extension CategoryEntity: Identifiable {

}
