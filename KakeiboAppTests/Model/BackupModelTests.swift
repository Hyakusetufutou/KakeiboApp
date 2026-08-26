//
//  BackupModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/27
//
//

import Testing
import Foundation
@testable import KakeiboApp

@Suite("BackupModel Tests")
struct BackupModelTests {

    // MARK: - BackupCategoryModel Tests

    @Test("CategoryModel と BackupCategoryModel の相互変換テスト")
    func categoryModelConversion() throws {
        // ダミーの CategoryModel を作成
        let originalCategory = try CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )

        // CategoryModel -> BackupCategoryModel の変換をテスト
        let backupCategory = BackupCategoryModel(from: originalCategory)
        #expect(backupCategory.id == originalCategory.id)
        #expect(backupCategory.name == originalCategory.name)
        #expect(backupCategory.color == originalCategory.color)
        #expect(backupCategory.type == originalCategory.type)
        #expect(backupCategory.isDefault == originalCategory.isDefault)

        // BackupCategoryModel -> CategoryModel の逆変換をテスト
        let restoredCategory = try backupCategory.toCategoryModel()
        #expect(restoredCategory.id == originalCategory.id)
        #expect(restoredCategory.name == originalCategory.name)
        #expect(restoredCategory.color == originalCategory.color)
        #expect(restoredCategory.type == originalCategory.type)
        #expect(restoredCategory.isDefault == originalCategory.isDefault)
    }

    // MARK: - BackupTransactionModel Tests

    @Test("TransactionModel と BackupTransactionModel の相互変換テスト")
    func transactionModelConversion() throws {
        let now = Date()
        let categoryId = UUID()

        // ダミーの TransactionModel を作成
        let originalTransaction = try TransactionModel(
            id: UUID(),
            title: "ランチ",
            memo: "カフェにて",
            amount: Decimal(1200),
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: categoryId
        )

        // TransactionModel -> BackupTransactionModel の変換をテスト
        let backupTransaction = BackupTransactionModel(from: originalTransaction)
        #expect(backupTransaction.id == originalTransaction.id)
        #expect(backupTransaction.title == originalTransaction.title)
        #expect(backupTransaction.memo == originalTransaction.memo)
        #expect(backupTransaction.amount == originalTransaction.amount)
        #expect(backupTransaction.date == originalTransaction.date)
        #expect(backupTransaction.type == originalTransaction.type)
        #expect(backupTransaction.categoryId == originalTransaction.categoryId)

        // BackupTransactionModel -> TransactionModel の逆変換をテスト
        let restoredTransaction = try backupTransaction.toTransactionModel()
        #expect(restoredTransaction.id == originalTransaction.id)
        #expect(restoredTransaction.title == originalTransaction.title)
        #expect(restoredTransaction.memo == originalTransaction.memo)
        #expect(restoredTransaction.amount == originalTransaction.amount)
        #expect(restoredTransaction.date == originalTransaction.date)
        #expect(restoredTransaction.type == originalTransaction.type)
        #expect(restoredTransaction.categoryId == originalTransaction.categoryId)
    }

    // MARK: - BackupData Codable Tests

    @Test("BackupData の JSON シリアライズ / デシリアライズ検証")
    func backupDataCodable() throws {
        let category = try CategoryModel(
            id: UUID(),
            name: "日用品",
            color: .blue,
            type: .expense,
            isDefault: true
        )
        let transaction = try TransactionModel(
            id: UUID(),
            title: "洗剤",
            memo: "",
            amount: Decimal(300),
            date: Date(),
            createdAt: Date(),
            updatedAt: Date(),
            type: .expense,
            categoryId: category.id
        )

        let backupData = BackupData(
            version: 1,
            createdAt: Date(),
            categories: [BackupCategoryModel(from: category)],
            transactions: [BackupTransactionModel(from: transaction)]
        )

        // JSONへのエンコードとデコードの検証
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(backupData)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedBackupData = try decoder.decode(BackupData.self, from: data)

        #expect(decodedBackupData.version == backupData.version)
        #expect(decodedBackupData.categories.count == 1)
        #expect(decodedBackupData.transactions.count == 1)
        #expect(decodedBackupData.categories.first?.name == "日用品")
        #expect(decodedBackupData.transactions.first?.title == "洗剤")
    }
}
