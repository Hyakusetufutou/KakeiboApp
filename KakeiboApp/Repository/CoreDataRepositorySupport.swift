//
//  CoreDataRepositorySupport.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/07/26
//
//

import CoreData

enum CoreDataRepositorySupport {
    static func makeBackgroundContext(
        from container: NSPersistentContainer
    ) -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.automaticallyMergesChangesFromParent = true
        return context
    }

    static func perform<T: Sendable>(
        on context: NSManagedObjectContext,
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        try await context.perform {
            try block(context)
        }
    }

    static func save(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }

    static func fetchEntity<Entity: NSManagedObject>(
        _ type: Entity.Type,
        by id: UUID,
        in context: NSManagedObjectContext
    ) throws -> Entity {
        let request = NSFetchRequest<Entity>(entityName: String(describing: type))
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw entityNotFoundError(for: type)
        }
        return entity
    }

    private static func entityNotFoundError(for type: Any.Type) -> CustomError {
        switch type {
        case is CategoryEntity.Type:
            return .categoryNotFoundError
        case is TransactionEntity.Type:
            return .transactionNotFoundError
        default:
            return .fetchError("Entity not found: \(type)")
        }
    }
}
