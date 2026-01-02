//
//  TransactionRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/04
//
//

import Foundation
import CoreData
import Combine

protocol TransactionRepositoryProtocol {
    func search(text: String?) -> Result<[TransactionModel], CustomError>
    func fetch(from startDate: Date?, to endDate: Date?) -> Result<[TransactionModel], CustomError>
    func add(_ transactionModel: TransactionModel) -> Result<Void, CustomError>
    func delete(_ transactionModel: TransactionModel) -> Result<Void, CustomError>
    func update(_ transactionModel: TransactionModel) -> Result<Void, CustomError>
}

class TransactionRepository: TransactionRepositoryProtocol {
    private let context: NSManagedObjectContext
    private let categoryRepository: CategoryRepository

    init(
        context: NSManagedObjectContext = PersistenceController.shared.container.viewContext,
        categoryRepository: CategoryRepository
    ) {
        self.context = context
        self.categoryRepository = categoryRepository
    }

    func search(text: String?) -> Result<[TransactionModel], CustomError> {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()

        if let text = text, !text.isEmpty {
            fetchRequest.predicate = NSPredicate(
                format: "title CONTAINS[c] %@ OR memo CONTAINS[c] %@",
                text,
                text
            )
        }

        do {
            let transactions = try context.fetch(fetchRequest)
            return .success(transactions.map { $0.toModel() })
        } catch {
            return .failure(.transactionNotFoundError)
        }
    }

    func fetch(from startDate: Date?, to endDate: Date?) -> Result<[TransactionModel], CustomError>
    {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()

        if let startDate = startDate, let endDate = endDate {
            fetchRequest.predicate = NSPredicate(
                format: "date >= %@ AND date <= %@",
                startDate as NSDate,
                endDate as NSDate
            )
        }

        do {
            let transactions = try context.fetch(fetchRequest)
            return .success(transactions.map { $0.toModel() })
        } catch {
            return .failure(.transactionNotFoundError)
        }
    }

    func add(_ transactionModel: TransactionModel) -> Result<Void, CustomError> {
        do {
            let category = try categoryRepository.fetchEntity(by: transactionModel.categoryId)
            let transaction = TransactionEntity(context: context)

            transaction.id = transactionModel.id
            transaction.amount = transactionModel.amount
            transaction.date = transactionModel.date
            transaction.createdAt = transactionModel.createAt
            transaction.upadtedAt = transactionModel.updatedAt
            transaction.title = transactionModel.title
            transaction.memo = transactionModel.memo
            transaction.type = transactionModel.type.rawValue
            transaction.category = category

            return saveContext()
        } catch let error as CustomError {
            return .failure(error)
        } catch {
            return .failure(.transactionNotFoundError)
        }
    }

    func delete(_ transactionModel: TransactionModel) -> Result<Void, CustomError> {
        do {
            let transaction = try fetchEntiry(by: transactionModel.id)
            context.delete(transaction)
            return saveContext()
        } catch let error as CustomError {
            return .failure(error)
        } catch {
            return .failure(.transactionNotFoundError)
        }
    }

    func update(_ transactionModel: TransactionModel) -> Result<Void, CustomError> {
        do {
            let transaction = try fetchEntiry(by: transactionModel.id)
            let category = try categoryRepository.fetchEntity(by: transactionModel.categoryId)

            transaction.id = transactionModel.id
            transaction.amount = transactionModel.amount
            transaction.date = transactionModel.date
            transaction.createdAt = transactionModel.createAt
            transaction.upadtedAt = transactionModel.updatedAt
            transaction.title = transactionModel.title
            transaction.memo = transactionModel.memo
            transaction.type = transactionModel.type.rawValue
            transaction.category = category

            return saveContext()
        } catch let error as CustomError {
            return .failure(error)
        } catch {
            return .failure(.transactionNotFoundError)
        }
    }

    private func fetchEntiry(by id: UUID) throws -> TransactionEntity {
        let fetchRequest: NSFetchRequest<TransactionEntity> = TransactionEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as NSUUID)

        guard let transaction = try context.fetch(fetchRequest).first else {
            throw CustomError.transactionNotFoundError
        }

        return transaction
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
