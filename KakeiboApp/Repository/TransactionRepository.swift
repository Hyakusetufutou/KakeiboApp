//
//  TransactionRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/04
//
//

import Foundation
import CoreData

protocol TransactionRepositoryProtocol {
    func search(text: String?) async -> Result<[TransactionModel], CustomError>
    func fetch(from startDate: Date?, to endDate: Date?, limit: Int?, offset: Int?) async -> Result<[TransactionModel], CustomError>
    func add(_ transactionModel: TransactionModel) async -> Result<Void, CustomError>
    func delete(_ transactionModel: TransactionModel) async -> Result<Void, CustomError>
    func update(_ transactionModel: TransactionModel) async -> Result<Void, CustomError>
}

final class TransactionRepository: TransactionRepositoryProtocol {
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }
    
    func search(text: String?) async -> Result<[TransactionModel], CustomError> {
        await context.perform {
            let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            
            if let text = text, !text.isEmpty {
                fetchRequest.predicate = NSPredicate(
                    format: "title CONTAINS[c] %@ OR memo CONTAINS[c] %@",
                    text, text
                )
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
            
            do {
                let transactions = try self.context.fetch(fetchRequest)
                return .success(transactions.map { $0.toModel() })
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func fetch(from startDate: Date?, to endDate: Date?, limit: Int? = nil, offset: Int? = nil) async -> Result<[TransactionModel], CustomError> {
        await context.perform {
            let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
            
            var predicates: [NSPredicate] = []
            if let startDate = startDate {
                predicates.append(NSPredicate(format: "date >= %@", startDate as NSDate))
            }
            if let endDate = endDate {
                predicates.append(NSPredicate(format: "date <= %@", endDate as NSDate))
            }
            
            if !predicates.isEmpty {
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \TransactionEntity.date, ascending: false)]
            
            if let limit = limit {
                fetchRequest.fetchLimit = limit
            }
            if let offset = offset {
                fetchRequest.fetchOffset = offset
            }
            
            do {
                let transactions = try self.context.fetch(fetchRequest)
                return .success(transactions.map { $0.toModel() })
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func add(_ transactionModel: TransactionModel) async -> Result<Void, CustomError> {
        await context.perform {
            do {
                guard let category = try self.fetchCategoryEntity(by: transactionModel.categoryId) else {
                    return .failure(.categoryNotFoundError)
                }
                
                let transaction = TransactionEntity(context: self.context)
                transaction.id = transactionModel.id
                transaction.amount = transactionModel.amount
                transaction.date = transactionModel.date
                transaction.createdAt = transactionModel.createdAt
                transaction.updatedAt = transactionModel.updatedAt
                transaction.title = transactionModel.title
                transaction.memo = transactionModel.memo
                transaction.type = transactionModel.type.rawValue
                transaction.category = category
                
                return self.saveContext()
            } catch let error as CustomError {
                return .failure(error)
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func delete(_ transactionModel: TransactionModel) async -> Result<Void, CustomError> {
        await context.perform {
            do {
                let transaction = try self.fetchEntity(by: transactionModel.id)
                self.context.delete(transaction)
                return self.saveContext()
            } catch let error as CustomError {
                return .failure(error)
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    func update(_ transactionModel: TransactionModel) async -> Result<Void, CustomError> {
        await context.perform {
            do {
                let transaction = try self.fetchEntity(by: transactionModel.id)
                guard let category = try self.fetchCategoryEntity(by: transactionModel.categoryId) else {
                    return .failure(.categoryNotFoundError)
                }
                
                transaction.amount = transactionModel.amount
                transaction.date = transactionModel.date
                transaction.createdAt = transactionModel.createdAt
                transaction.updatedAt = transactionModel.updatedAt
                transaction.title = transactionModel.title
                transaction.memo = transactionModel.memo
                transaction.type = transactionModel.type.rawValue
                transaction.category = category
                
                return self.saveContext()
            } catch let error as CustomError {
                return .failure(error)
            } catch {
                return .failure(.fetchError(error.localizedDescription))
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchEntity(by id: UUID) throws -> TransactionEntity {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        fetchRequest.fetchLimit = 1
        
        guard let transaction = try context.fetch(fetchRequest).first else {
            throw CustomError.transactionNotFoundError
        }
        return transaction
    }
    
    private func fetchCategoryEntity(by id: UUID) throws -> CategoryEntity? {
        let fetchRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as NSUUID)
        fetchRequest.fetchLimit = 1
        
        return try context.fetch(fetchRequest).first
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
