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
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.context = CoreDataRepositorySupport.makeBackgroundContext(from: container)
    }

    func fetchAll() async throws -> [CategoryModel] {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let request: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)
            ]
            return try context.fetch(request).map { try $0.toModel() }
        }
    }

    func fetch(by id: UUID) async throws -> CategoryModel {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let entity = try CoreDataRepositorySupport.fetchEntity(
                CategoryEntity.self,
                by: id,
                in: context
            )
            return try entity.toModel()
        }
    }

    func add(_ categoryModel: CategoryModel) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let entity = CategoryEntity(context: context)
            Self.map(model: categoryModel, to: entity)

            try CoreDataRepositorySupport.save(context)
        }
    }

    func update(_ categoryModel: CategoryModel) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let entity = try CoreDataRepositorySupport.fetchEntity(
                CategoryEntity.self,
                by: categoryModel.id,
                in: context
            )
            Self.map(model: categoryModel, to: entity)

            try CoreDataRepositorySupport.save(context)
        }
    }

    func delete(_ categoryModel: CategoryModel) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let entity = try CoreDataRepositorySupport.fetchEntity(
                CategoryEntity.self,
                by: categoryModel.id,
                in: context
            )
            context.delete(entity)

            try CoreDataRepositorySupport.save(context)
        }
    }

    // MARK: - Private Helpers

    private static func map(model: CategoryModel, to entity: CategoryEntity) {
        entity.id = model.id
        entity.name = model.name
        entity.color = model.color.rawValue
        entity.type = model.type.rawValue
        entity.isDefault = model.isDefault
    }
}
