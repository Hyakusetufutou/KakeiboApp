//
//  TransactionRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/04
//
//

import CoreData

// MARK: - Transaction Repository Protocol
protocol TransactionRepositoryProtocol: Sendable {
    func fetch(
        from start: Date?,
        to end: Date?,
        limit: Int?,
        offset: Int?
    ) async throws -> [TransactionModel]
    func search(text: String?) async throws -> [TransactionModel]
    func add(_ model: TransactionModel) async throws
    func update(_ model: TransactionModel) async throws
    func delete(_ model: TransactionModel) async throws
}

// MARK: - Transaction Repository Implementation
actor TransactionRepository: TransactionRepositoryProtocol {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    func fetch(
        from start: Date?,
        to end: Date?,
        limit: Int?,
        offset: Int?
    ) async throws -> [TransactionModel] {
        return try await container.performBackgroundTask { context in
            let request = TransactionEntity.fetchRequest()

            // Build predicates
            var predicates: [NSPredicate] = []
            if let start = start {
                predicates.append(NSPredicate(format: "date >= %@", start as NSDate))
            }
            if let end = end {
                predicates.append(NSPredicate(format: "date <= %@", end as NSDate))
            }
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            // Sort by date descending
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)
            ]

            // Apply pagination
            if let limit = limit {
                request.fetchLimit = limit
            }
            if let offset = offset {
                request.fetchOffset = offset
            }

            return try context.fetch(request).map { $0.toModel() }
        }
    }

    func search(text: String?) async throws -> [TransactionModel] {
        return try await container.performBackgroundTask { context in
            let request = TransactionEntity.fetchRequest()

            if let text = text, !text.isEmpty {
                request.predicate = NSPredicate(
                    format: "title CONTAINS[c] %@ OR memo CONTAINS[c] %@",
                    text,
                    text
                )
            }

            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)
            ]

            return try context.fetch(request).map { $0.toModel() }
        }
    }

    func add(_ model: TransactionModel) async throws {
        try await container.performBackgroundTask { context in
            let category = try self.fetchCategory(by: model.categoryId, in: context)

            let entity = TransactionEntity(context: context)
            entity.id = model.id
            entity.amount = model.amount
            entity.date = model.date
            entity.title = model.title
            entity.memo = model.memo
            entity.type = model.type.rawValue
            entity.createdAt = model.createdAt
            entity.updatedAt = model.updatedAt
            entity.category = category

            try context.save()
        }
    }

    func update(_ model: TransactionModel) async throws {
        try await container.performBackgroundTask { context in
            // Fetch existing transaction
            var entity = try self.fetchEntity(by: model.id, in: context)

            // Fetch new category
            let category = try self.fetchCategory(by: model.categoryId, in: context)

            // Update properties
            entity.amount = model.amount
            entity.date = model.date
            entity.title = model.title
            entity.memo = model.memo
            entity.createdAt = model.createdAt
            entity.updatedAt = model.updatedAt
            entity.category = category

            try context.save()
        }
    }

    func delete(_ model: TransactionModel) async throws {
        try await container.performBackgroundTask { context in
            let entity = try self.fetchEntity(by: model.id, in: context)
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Private Helpers
    private func fetchEntity(
        by id: UUID,
        in context: NSManagedObjectContext
    ) throws -> TransactionEntity {
        let request = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw CustomError.transactionNotFoundError
        }
        return entity
    }

    private func fetchCategory(
        by id: UUID,
        in context: NSManagedObjectContext
    ) throws -> CategoryEntity {
        let request = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let category = try context.fetch(request).first else {
            throw CustomError.categoryNotFoundError
        }
        return category
    }
}
