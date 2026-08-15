//
//  GoalEntity+CoreDataProperties.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/07/27
//
//
//

public import Foundation
public import CoreData

public typealias GoalEntityCoreDataPropertiesSet = NSSet

extension GoalEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GoalEntity> {
        return NSFetchRequest<GoalEntity>(entityName: "GoalEntity")
    }

    @NSManaged public var endDate: Date
    @NSManaged public var id: UUID
    @NSManaged public var startDate: Date
    @NSManaged public var targetAmount: Double
    @NSManaged public var title: String
    @NSManaged public var type: String
    @NSManaged public var category: CategoryEntity

}

extension GoalEntity: Identifiable {

}
