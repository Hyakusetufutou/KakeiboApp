//
//  BackupRepository.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/25
//
//

import CoreData

protocol BackupRepositoryProtocol: Sendable {
    func create() async throws -> BackupData
    func restore(addCategories: [CategoryModel], addTransactions: [TransactionModel]) async throws
}

actor BackupRepository: BackupRepositoryProtocol {
    private let context: NSManagedObjectContext

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.context = CoreDataRepositorySupport.makeBackgroundContext(from: container)
    }

    func create() async throws -> BackupData {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let categoryRequest: NSFetchRequest<CategoryEntity> = CategoryEntity.fetchRequest()
            let transactionRequest: NSFetchRequest<TransactionEntity> =
                TransactionEntity.fetchRequest()

            let categories = try context.fetch(categoryRequest)
                .map { BackupCategoryModel(from: try $0.toModel()) }
            let transactions = try context.fetch(transactionRequest)
                .map { BackupTransactionModel(from: try $0.toModel()) }

            return BackupData(
                version: 1,
                createdAt: Date(),
                categories: categories,
                transactions: transactions
            )
        }
    }

    func restore(addCategories: [CategoryModel], addTransactions: [TransactionModel]) async throws {
        try await CoreDataRepositorySupport.perform(on: context) { context in
            let transactions = try context.fetch(
                TransactionEntity.fetchRequest()
            )

            for transaction in transactions {
                context.delete(transaction)
            }

            let recurringTransactions = try context.fetch(
                RecurringTransactionEntity.fetchRequest()
            )

            for recurringTransaction in recurringTransactions {
                context.delete(recurringTransaction)
            }

            let goals = try context.fetch(
                GoalEntity.fetchRequest()
            )

            for goal in goals {
                context.delete(goal)
            }

            let categories = try context.fetch(
                CategoryEntity.fetchRequest()
            )

            for category in categories {
                context.delete(category)
            }

            do {
                var categoryMap: [UUID: CategoryEntity] = [:]

                for category in addCategories {
                    let entity = CategoryEntity(context: context)

                    entity.id = category.id
                    entity.name = category.name
                    entity.type = category.type.rawValue
                    entity.color = category.color.rawValue
                    entity.isDefault = category.isDefault

                    categoryMap[category.id] = entity
                }

                for transaction in addTransactions {
                    let categoryID = transaction.categoryId

                    guard let category = categoryMap[categoryID] else {
                        throw CustomError.categoryNotFoundError
                    }

                    let entity = TransactionEntity(context: context)

                    entity.id = transaction.id
                    entity.title = transaction.title
                    entity.memo = transaction.memo
                    entity.amount = NSDecimalNumber(
                        decimal: transaction.amount
                    )
                    entity.date = transaction.date
                    entity.createdAt = transaction.createdAt
                    entity.updatedAt = transaction.updatedAt
                    entity.type = transaction.type.rawValue
                    entity.category = category
                }

                try context.save()
            } catch {
                context.rollback()
                throw error
            }
        }
    }
}
