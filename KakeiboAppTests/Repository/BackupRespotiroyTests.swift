//
//  BackupRespotiroyTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/28
//
//

import Testing
import CoreData
import Foundation
@testable import KakeiboApp

@Suite("BackupRepository Tests")
struct BackupRepositoryTests {

    /// テスト用のインメモリ CoreData コンテナを作成
    private func makeInMemoryContainer() -> NSPersistentContainer {
        let container = NSPersistentContainer(name: "KakeiboApp")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load in-memory store: \(error)")
            }
        }
        return container
    }

    // MARK: - create() Tests

    @Test("create: CoreData内のカテゴリとトランザクションを正常に取得してBackupDataを作成できるか")
    func testCreateSuccess() async throws {
        let container = makeInMemoryContainer()
        let context = container.viewContext

        // テスト用のエンティティを作成・初期化
        let categoryEntity = CategoryEntity(context: context)
        categoryEntity.id = UUID()
        categoryEntity.name = "食費"
        categoryEntity.type = TransactionType.expense.rawValue
        categoryEntity.color = CategoryColor.red.rawValue
        categoryEntity.isDefault = false
        categoryEntity.sortOrder = 0

        let transactionEntity = TransactionEntity(context: context)
        transactionEntity.id = UUID()
        transactionEntity.title = "ランチ"
        transactionEntity.memo = "カフェ"
        transactionEntity.amount = NSDecimalNumber(value: 1000)
        transactionEntity.date = Date()
        transactionEntity.createdAt = Date()
        transactionEntity.updatedAt = Date()
        transactionEntity.type = TransactionType.expense.rawValue
        transactionEntity.category = categoryEntity

        try context.save()

        let repository = BackupRepository(container: container)
        let backupData = try await repository.create()

        #expect(backupData.version == 1)
        #expect(backupData.categories.count == 1)
        #expect(backupData.categories.first?.name == "食費")
        #expect(backupData.transactions.count == 1)
        #expect(backupData.transactions.first?.title == "ランチ")
    }

    // MARK: - restore() Tests

    @Test("restore: 既存データの全削除と新しいカテゴリ・トランザクションの書き込みが成功するか")
    func testRestoreSuccess() async throws {
        let container = makeInMemoryContainer()
        let context = container.viewContext

        // 1. 事前データ（リストア処理で削除されるべきデータ）の準備
        let oldCategory = CategoryEntity(context: context)
        oldCategory.id = UUID()
        oldCategory.name = "旧カテゴリ"
        oldCategory.type = TransactionType.expense.rawValue
        oldCategory.color = CategoryColor.red.rawValue
        oldCategory.isDefault = false
        oldCategory.sortOrder = 0

        let oldTransaction = TransactionEntity(context: context)
        oldTransaction.id = UUID()
        oldTransaction.title = "旧データ"
        oldTransaction.memo = ""
        oldTransaction.amount = NSDecimalNumber(value: 100)
        oldTransaction.date = Date()
        oldTransaction.createdAt = Date()
        oldTransaction.updatedAt = Date()
        oldTransaction.type = TransactionType.expense.rawValue
        oldTransaction.category = oldCategory

        let oldRecurring = RecurringTransactionEntity(context: context)
        oldRecurring.id = UUID()
        oldRecurring.title = "定期支払"
        oldRecurring.amount = 1000.0
        oldRecurring.frequency = "monthly"
        oldRecurring.type = TransactionType.expense.rawValue
        oldRecurring.startDate = Date()
        oldRecurring.endDate = Date()
        oldRecurring.category = oldCategory

        let oldGoal = GoalEntity(context: context)
        oldGoal.id = UUID()
        oldGoal.title = "目標"
        oldGoal.targetAmount = 50000.0
        oldGoal.startDate = Date()
        oldGoal.endDate = Date()
        oldGoal.type = TransactionType.expense.rawValue
        oldGoal.category = oldCategory

        try context.save()

        // 2. 復元用データの準備
        let newCategoryId = UUID()
        let newCategory = try CategoryModel(
            id: newCategoryId,
            name: "日用品",
            color: .blue,
            type: .expense,
            isDefault: false
        )
        let newTransaction = try TransactionModel(
            id: UUID(),
            title: "洗剤",
            memo: "ドラッグストア",
            amount: Decimal(500),
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            type: .expense,
            categoryId: newCategoryId
        )

        let repository = BackupRepository(container: container)
        try await repository.restore(
            addCategories: [newCategory],
            addTransactions: [newTransaction]
        )

        // 3. 検証: 旧データが全削除され、新データのみが存在することを確認
        let fetchedCategories = try context.fetch(CategoryEntity.fetchRequest())
        let fetchedTransactions = try context.fetch(TransactionEntity.fetchRequest())
        let fetchedRecurring = try context.fetch(RecurringTransactionEntity.fetchRequest())
        let fetchedGoals = try context.fetch(GoalEntity.fetchRequest())

        #expect(fetchedCategories.count == 1)
        #expect(fetchedCategories.first?.name == "日用品")
        #expect(fetchedTransactions.count == 1)
        #expect(fetchedTransactions.first?.title == "洗剤")
        #expect(fetchedRecurring.isEmpty)
        #expect(fetchedGoals.isEmpty)
    }

    @Test("restore 異常系: 対応するカテゴリが存在しない場合、エラーがスローされロールバックされるか")
    func testRestoreCategoryNotFoundThrowsError() async throws {
        let container = makeInMemoryContainer()
        let repository = BackupRepository(container: container)

        let category = try CategoryModel(
            id: UUID(),
            name: "趣味",
            color: .green,
            type: .expense,
            isDefault: false
        )
        // 存在しないカテゴリIDを参照するトランザクション
        let invalidTransaction = try TransactionModel(
            id: UUID(),
            title: "ゲーム",
            memo: "",
            amount: Decimal(5000),
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            type: .expense,
            categoryId: UUID()  // 未登録のUUID
        )

        await #expect(throws: (any Error).self) {
            try await repository.restore(
                addCategories: [category],
                addTransactions: [invalidTransaction]
            )
        }

        // ロールバック処理により、DB内にカテゴリが書き込まれていないことを確認
        let context = container.viewContext
        let fetchedCategories = (try? context.fetch(CategoryEntity.fetchRequest())) ?? []
        #expect(fetchedCategories.isEmpty)
    }
}
