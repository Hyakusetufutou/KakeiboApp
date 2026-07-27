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
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.context = CoreDataRepositorySupport.makeBackgroundContext(from: container)
    }

    func fetch(
        from start: Date?,
        to end: Date?,
        limit: Int?,
        offset: Int?
    ) async throws -> [TransactionModel] {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.relationshipKeyPathsForPrefetching = ["category"]

            var predicates: [NSPredicate] = []
            if let start {
                predicates.append(NSPredicate(format: "date >= %@", start as NSDate))
            }
            if let end {
                predicates.append(NSPredicate(format: "date <= %@", end as NSDate))
            }
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }

            request.sortDescriptors = Self.transactionSortDescriptors

            if let limit { request.fetchLimit = limit }
            if let offset { request.fetchOffset = offset }

            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func search(text: String?) async throws -> [TransactionModel] {
        guard let normalizedText = StoreSupport.normalizedSearchText(text) else {
            return []
        }

        return try await CoreDataRepositorySupport.perform(on: context) { context in
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.relationshipKeyPathsForPrefetching = ["category"]
            request.predicate = NSPredicate(
                format: "title CONTAINS[c] %@ OR memo CONTAINS[c] %@",
                normalizedText,
                normalizedText
            )
            request.sortDescriptors = Self.transactionSortDescriptors

            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func add(_ model: TransactionModel) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let category = try CoreDataRepositorySupport.fetchEntity(
                CategoryEntity.self,
                by: model.categoryId,
                in: context
            )

            let entity = TransactionEntity(context: context)
            Self.map(model: model, to: entity, category: category)

            try CoreDataRepositorySupport.save(context)
        }
    }

    func update(_ model: TransactionModel) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let entity = try CoreDataRepositorySupport.fetchEntity(
                TransactionEntity.self,
                by: model.id,
                in: context
            )
            let category = try CoreDataRepositorySupport.fetchEntity(
                CategoryEntity.self,
                by: model.categoryId,
                in: context
            )

            Self.map(model: model, to: entity, category: category)

            try CoreDataRepositorySupport.save(context)
        }
    }

    func delete(_ model: TransactionModel) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let entity = try CoreDataRepositorySupport.fetchEntity(
                TransactionEntity.self,
                by: model.id,
                in: context
            )
            context.delete(entity)
            try CoreDataRepositorySupport.save(context)
        }
    }

    // MARK: - Private Helpers

    private static var transactionSortDescriptors: [NSSortDescriptor] {
        [
            NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false),
            NSSortDescriptor(keyPath: \TransactionEntity.id, ascending: false),
        ]
    }

    private static func map(
        model: TransactionModel,
        to entity: TransactionEntity,
        category: CategoryEntity
    ) {
        entity.id = model.id
        entity.amount = NSDecimalNumber(decimal: model.amount)
        entity.date = model.date
        entity.title = model.title
        entity.memo = model.memo
        entity.type = model.type.rawValue
        entity.createdAt = model.createdAt
        entity.updatedAt = model.updatedAt
        entity.category = category
    }
}
