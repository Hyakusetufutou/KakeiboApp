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
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        self.context = container.newBackgroundContext()
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // 他のコンテキスト（メインコンテキスト等）での保存内容をこのバックグラウンド
        // コンテキストにも自動反映させ、複数コンテキスト間の不整合を防ぐ。
        self.context.automaticallyMergesChangesFromParent = true
    }

    func fetch(
        from start: Date?,
        to end: Date?,
        limit: Int?,
        offset: Int?
    ) async throws -> [TransactionModel] {
        try await performBackgroundTask { context in
            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.relationshipKeyPathsForPrefetching = ["category"]

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

            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)
            ]

            if let limit = limit { request.fetchLimit = limit }
            if let offset = offset { request.fetchOffset = offset }

            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func search(text: String?) async throws -> [TransactionModel] {
        try await performBackgroundTask { context in
            guard let text = text, !text.isEmpty else {
                return []
            }

            let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            request.relationshipKeyPathsForPrefetching = ["category"]
            request.predicate = NSPredicate(
                format: "title CONTAINS[c] %@ OR memo CONTAINS[c] %@",
                text,
                text
            )
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)
            ]

            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func add(_ model: TransactionModel) async throws {
        try await performBackgroundTask { context in
            let category = try self.fetchCategoryEntity(by: model.categoryId, in: context)

            let entity = TransactionEntity(context: context)
            self.map(model: model, to: entity, category: category)

            try self.save(in: context)
        }
    }

    func update(_ model: TransactionModel) async throws {
        try await performBackgroundTask { context in
            let entity = try self.fetchEntity(by: model.id, in: context)
            let category = try self.fetchCategoryEntity(by: model.categoryId, in: context)

            self.map(model: model, to: entity, category: category)

            try self.save(in: context)
        }
    }

    func delete(_ model: TransactionModel) async throws {
        try await performBackgroundTask { context in
            let entity = try self.fetchEntity(by: model.id, in: context)
            context.delete(entity)
            try self.save(in: context)
        }
    }

    // MARK: - Private Helpers

    /// バックグラウンドコンテキスト上でブロックを実行する共通ラッパー。
    /// 各メソッドで `context.perform` を個別に書く重複を避けるために用意。
    private func performBackgroundTask<T: Sendable>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = self.context
        return try await context.perform {
            try block(context)
        }
    }

    /// context.performから呼び出すこと
    nonisolated private func map(
        model: TransactionModel,
        to entity: TransactionEntity,
        category: CategoryEntity
    ) {
        entity.id = model.id
        entity.amount = model.amount
        entity.date = model.date
        entity.title = model.title
        entity.memo = model.memo
        entity.type = model.type.rawValue
        entity.createdAt = model.createdAt
        entity.updatedAt = model.updatedAt
        entity.category = category
    }

    /// context.performから呼び出すこと
    nonisolated private func fetchEntity(
        by id: UUID,
        in context: NSManagedObjectContext
    ) throws -> TransactionEntity {
        let request: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw CustomError.transactionNotFoundError
        }
        return entity
    }

    /// context.performから呼び出すこと
    nonisolated private func fetchCategoryEntity(
        by id: UUID,
        in context: NSManagedObjectContext
    ) throws -> CategoryEntity {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let category = try context.fetch(request).first else {
            throw CustomError.categoryNotFoundError
        }
        return category
    }

    /// context.performから呼び出すこと
    nonisolated private func save(in context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
