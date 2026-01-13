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
    func fetchAll() async -> Result<[CategoryModel], CustomError>
    func fetch(by id: UUID) async -> Result<CategoryModel, CustomError>
    func add(_ categoryModel: CategoryModel) async -> Result<Void, CustomError>
    func delete(_ categoryModel: CategoryModel) async -> Result<Void, CustomError>
    func update(_ categoryModel: CategoryModel) async -> Result<Void, CustomError>
}

final class CategoryRepository: CategoryRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func fetchAll() async -> Result<[CategoryModel], CustomError> {
        await context.perform {
            let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \CategoryEntity.name, ascending: true)]
            
            do {
                let categories = try self.context.fetch(fetchRequest)
                return .success(categories.map { $0.toModel() })
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func fetch(by id: UUID) async -> Result<CategoryModel, CustomError> {
        await context.perform {
            do {
                let category = try self.fetchEntity(by: id)
                return .success(category.toModel())
            } catch let error as CustomError {
                return .failure(error)
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func add(_ categoryModel: CategoryModel) async -> Result<Void, CustomError> {
        await context.perform {
            let category = CategoryEntity(context: self.context)
            category.id = categoryModel.id
            category.name = categoryModel.name
            category.color = AppTheme.colorToString(categoryModel.color)
            category.type = categoryModel.type.rawValue
            category.isDefault = categoryModel.isDefault
            
            return self.saveContext()
        }
    }
    
    func delete(_ categoryModel: CategoryModel) async -> Result<Void, CustomError> {
        await context.perform {
            do {
                let category = try self.fetchEntity(by: categoryModel.id)
                self.context.delete(category)
                return self.saveContext()
            } catch let error as CustomError {
                return .failure(error)
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func update(_ categoryModel: CategoryModel) async -> Result<Void, CustomError> {
        await context.perform {
            do {
                let category = try self.fetchEntity(by: categoryModel.id)
                category.name = categoryModel.name
                category.color = AppTheme.colorToString(categoryModel.color)
                category.type = categoryModel.type.rawValue
                category.isDefault = categoryModel.isDefault
                
                return self.saveContext()
            } catch let error as CustomError {
                return .failure(error)
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchEntity(by id: UUID) throws -> CategoryEntity {
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
