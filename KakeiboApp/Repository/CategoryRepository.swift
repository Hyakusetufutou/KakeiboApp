//
//  CategoryRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//

import CoreData

// MARK: - Category Repository Protocol
protocol CategoryRepositoryProtocol: Sendable {
    func fetchAll() async throws -> [CategoryModel]
    func fetch(by id: UUID) async throws -> CategoryModel
    func add(_ categoryModel: CategoryModel) async throws
    func delete(_ categoryModel: CategoryModel) async throws
    func update(_ categoryModel: CategoryModel) async throws
}

// MARK: - Category Repository Implementation
actor CategoryRepository: CategoryRepositoryProtocol {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        self.context = container.newBackgroundContext()
        self.context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.context.automaticallyMergesChangesFromParent = true
    }

    func fetchAll() async throws -> [CategoryModel] {
        try await performBackgroundTask { context in
            let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)
            ]
            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func fetch(by id: UUID) async throws -> CategoryModel {
        try await performBackgroundTask { context in
            let entity = try self.fetchEntity(by: id, in: context)
            return try entity.toModel()
        }
    }

    func add(_ categoryModel: CategoryModel) async throws {
        try await performBackgroundTask { context in
            let entity = CategoryEntity(context: context)
            self.map(model: categoryModel, to: entity)

            try self.save(in: context)
        }
    }

    func update(_ categoryModel: CategoryModel) async throws {
        try await performBackgroundTask { context in
            let entity = try self.fetchEntity(by: categoryModel.id, in: context)
            self.map(model: categoryModel, to: entity)

            try self.save(in: context)
        }
    }

    func delete(_ categoryModel: CategoryModel) async throws {
        try await performBackgroundTask { context in
            let entity = try self.fetchEntity(by: categoryModel.id, in: context)
            context.delete(entity)

            try self.save(in: context)
        }
    }

    // MARK: - Private Helpers

    /// バックグラウンドコンテキスト上でブロックを実行する共通ラッパー。
    private func performBackgroundTask<T: Sendable>(
        _ block: @escaping (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        let context = self.context
        return try await context.perform {
            try block(context)
        }
    }

    /// context.performから呼び出すこと
    nonisolated private func map(model: CategoryModel, to entity: CategoryEntity) {
        entity.id = model.id
        entity.name = model.name
        entity.color = model.color.rawValue
        entity.type = model.type.rawValue
        entity.isDefault = model.isDefault
    }

    /// context.performから呼び出すこと
    nonisolated private func fetchEntity(
        by id: UUID,
        in context: NSManagedObjectContext
    ) throws -> CategoryEntity {
        let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        request.fetchLimit = 1

        guard let entity = try context.fetch(request).first else {
            throw CustomError.categoryNotFoundError
        }
        return entity
    }

    /// context.performから呼び出すこと
    nonisolated private func save(in context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
