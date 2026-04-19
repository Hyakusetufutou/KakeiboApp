//
//  CategoryRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
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

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    func fetchAll() async throws -> [CategoryModel] {
        return try await container.performBackgroundTask { context in
            let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)
            ]
            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func fetch(by id: UUID) async throws -> CategoryModel {
        return try await container.performBackgroundTask { context in
            let entity = try self.fetchEntity(by: id, in: context)
            return try entity.toModel()
        }
    }

    func add(_ categoryModel: CategoryModel) async throws {
        try await container.performBackgroundTask { context in
            let entity = CategoryEntity(context: context)
            entity.id = categoryModel.id
            entity.name = categoryModel.name
            entity.color = categoryModel.color.rawValue
            entity.type = categoryModel.type.rawValue
            entity.isDefault = categoryModel.isDefault
            try context.save()
        }
    }

    func update(_ categoryModel: CategoryModel) async throws {
        try await container.performBackgroundTask { context in
            let entity = try self.fetchEntity(by: categoryModel.id, in: context)
            entity.name = categoryModel.name
            entity.color = categoryModel.color.rawValue
            entity.type = categoryModel.type.rawValue
            entity.isDefault = categoryModel.isDefault
            try context.save()
        }
    }

    func delete(_ categoryModel: CategoryModel) async throws {
        try await container.performBackgroundTask { context in
            let entity = try self.fetchEntity(by: categoryModel.id, in: context)
            context.delete(entity)
            try context.save()
        }
    }

    // MARK: - Private Helpers
    private func fetchEntity(
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
}
