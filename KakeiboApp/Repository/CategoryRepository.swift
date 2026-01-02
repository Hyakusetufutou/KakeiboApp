//
//  CategoryRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import Foundation
import CoreData

protocol CategoryRepositoryProtocol {
    func fetchAll() -> Result<[CategoryModel], CustomError>
    func fetch(by id: UUID) -> Result<CategoryModel, CustomError>
    func add(_ categoryModel: CategoryModel) -> Result<Void, CustomError>
    func delete(_ categoryModel: CategoryModel) -> Result<Void, CustomError>
    func update(_ categoryModel: CategoryModel) -> Result<Void, CustomError>
    func fetchEntity(by id: UUID) throws -> CategoryEntity
}

class CategoryRepository: CategoryRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func fetchAll() -> Result<[CategoryModel], CustomError> {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()

        do {
            let categories = try context.fetch(fetchRequest)
            return .success(categories.map { $0.toModel() })
        } catch {
            return .failure(.categoryNotFoundError)
        }
    }

    func fetch(by id: UUID) -> Result<CategoryModel, CustomError> {
        do {
            let category = try fetchEntity(by: id)
            return .success(category.toModel())
        } catch {
            return .failure(.categoryNotFoundError)
        }
    }

    func add(_ categoryModel: CategoryModel) -> Result<Void, CustomError> {
        let category = CategoryEntity(context: context)

        category.id = categoryModel.id
        category.name = categoryModel.name
        category.color = AppTheme.colorToString(categoryModel.color)
        category.type = categoryModel.type.rawValue
        category.isDefault = categoryModel.isDefault

        return saveContext()
    }

    func delete(_ categoryModel: CategoryModel) -> Result<Void, CustomError> {
        do {
            let category = try fetchEntity(by: categoryModel.id)
            context.delete(category)
            return saveContext()
        } catch let error as CustomError {
            return .failure(error)
        } catch {
            return .failure(.saveError)
        }
    }

    func update(_ categoryModel: CategoryModel) -> Result<Void, CustomError> {
        do {
            let category = try fetchEntity(by: categoryModel.id)
            category.name = categoryModel.name
            category.color = AppTheme.colorToString(categoryModel.color)
            category.type = categoryModel.type.rawValue
            category.isDefault = categoryModel.isDefault
            return saveContext()
        } catch let error as CustomError {
            return .failure(error)
        } catch {
            return .failure(.saveError)
        }
    }

    func fetchEntity(by id: UUID) throws -> CategoryEntity {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        fetchRequest.fetchLimit = 1

        guard let category = try context.fetch(fetchRequest).first else {
            throw CustomError.categoryNotFoundError
        }

        return category
    }

    private func saveContext() -> Result<Void, CustomError> {
        do {
            if context.hasChanges {
                try context.save()
            }
            return .success(())
        } catch {
            context.rollback()
            return .failure(.saveError)
        }
    }
}
