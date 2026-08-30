//
//  BackupUseCaseTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/29
//
//

import Foundation
import Testing
@testable import KakeiboApp

// MARK: - Mocks

actor MockBackupRepository: BackupRepositoryProtocol {
    var createResult: Result<BackupData, Error> = .failure(CustomError.categoryNotFoundError)
    var restoreHandler: (([CategoryModel], [TransactionModel]) throws -> Void)?

    private(set) var restoreCalled = false
    private(set) var passedCategories: [CategoryModel] = []
    private(set) var passedTransactions: [TransactionModel] = []

    func setCreateResult(_ result: Result<BackupData, Error>) {
        self.createResult = result
    }

    func setRestoreHandler(
        _ handler: @escaping ([CategoryModel], [TransactionModel]) throws -> Void
    ) {
        self.restoreHandler = handler
    }

    func create() async throws -> BackupData {
        try createResult.get()
    }

    func restore(addCategories: [CategoryModel], addTransactions: [TransactionModel]) async throws {
        restoreCalled = true
        passedCategories = addCategories
        passedTransactions = addTransactions
        try restoreHandler?(addCategories, addTransactions)
    }
}

final class MockBackupService: BackupServiceProtocol, @unchecked Sendable {
    var createBackupResult: Result<Data, Error> = .failure(CustomError.categoryNotFoundError)
    var decodeBackupResult: Result<BackupData, Error> = .failure(CustomError.categoryNotFoundError)

    func createBackUp(categories: [CategoryModel], transactions: [TransactionModel]) throws -> Data
    {
        try createBackupResult.get()
    }

    func decodeBackUp(from data: Data) throws -> BackupData {
        try decodeBackupResult.get()
    }
}

// MARK: - CreateBackupUseCase Tests

@Suite("CreateBackupUseCase Tests")
struct CreateBackupUseCaseTests {

    @Test("正常系: Repositoryからの取得データをモデル変換し、BackupServiceでData化して返却できるか")
    func testExecuteSuccess() async throws {
        let repository = MockBackupRepository()
        let service = MockBackupService()
        let useCase = CreateBackupUseCase(backupRepository: repository, backupService: service)

        let categoryId = UUID()
        let backupCategory = BackupCategoryModel(
            from: try CategoryModel(
                id: categoryId,
                name: "食費",
                color: .red,
                type: .expense,
                isDefault: false
            )
        )
        let backupTransaction = BackupTransactionModel(
            from: try TransactionModel(
                id: UUID(),
                title: "ランチ",
                memo: "",
                amount: Decimal(1000),
                date: Date(),
                createdAt: Date(),
                updatedAt: Date(),
                type: .expense,
                categoryId: categoryId
            )
        )

        let mockBackupData = BackupData(
            version: 1,
            createdAt: Date(),
            categories: [backupCategory],
            transactions: [backupTransaction]
        )
        let expectedData = "testData".data(using: .utf8)!

        await repository.setCreateResult(.success(mockBackupData))
        service.createBackupResult = .success(expectedData)

        let result = try await useCase.execute()
        #expect(result == expectedData)
    }

    @Test("異常系: Repository処理でエラーが発生した場合、例外がスローされるか")
    func testExecuteRepositoryFailure() async {
        let repository = MockBackupRepository()
        let service = MockBackupService()
        let useCase = CreateBackupUseCase(backupRepository: repository, backupService: service)

        await repository.setCreateResult(.failure(CustomError.categoryNotFoundError))

        await #expect(throws: (any Error).self) {
            try await useCase.execute()
        }
    }
}

// MARK: - RestoreBackupUseCase Tests

@Suite("RestoreBackupUseCase Tests")
struct RestoreBackupUseCaseTests {

    @Test("正常系: Dataをデコードしてカテゴリとトランザクションの両方をモデル変換し、Repositoryのrestoreを呼出せるか")
    func testExecuteSuccess() async throws {
        let repository = MockBackupRepository()
        let service = MockBackupService()
        let useCase = RestoreBackupUseCase(backupRepository: repository, backupService: service)

        let categoryId = UUID()
        let backupCategory = BackupCategoryModel(
            from: try CategoryModel(
                id: categoryId,
                name: "交通費",
                color: .blue,
                type: .expense,
                isDefault: false
            )
        )

        // transactions.map の中身を通過させるため、BackupTransactionModel を設定
        let backupTransaction = BackupTransactionModel(
            from: try TransactionModel(
                id: UUID(),
                title: "電車代",
                memo: "移動",
                amount: Decimal(300),
                date: Date(),
                createdAt: Date(),
                updatedAt: Date(),
                type: .expense,
                categoryId: categoryId
            )
        )

        let backupData = BackupData(
            version: 1,
            createdAt: Date(),
            categories: [backupCategory],
            transactions: [backupTransaction]  // 空配列にせず要素を入れる
        )

        service.decodeBackupResult = .success(backupData)
        await repository.setRestoreHandler { _, _ in }

        let inputData = "validJson".data(using: .utf8)!
        try await useCase.execute(data: inputData)

        let isCalled = await repository.restoreCalled
        let categories = await repository.passedCategories
        let transactions = await repository.passedTransactions

        #expect(isCalled)
        #expect(categories.count == 1)
        #expect(categories.first?.name == "交通費")

        // transactions の変換も正常に行われたか検証
        #expect(transactions.count == 1)
        #expect(transactions.first?.title == "電車代")
    }

    @Test("異常系: Serviceでのデコード処理に失敗した場合、例外がスローされるか")
    func testExecuteDecodeFailure() async {
        let repository = MockBackupRepository()
        let service = MockBackupService()
        let useCase = RestoreBackupUseCase(backupRepository: repository, backupService: service)

        service.decodeBackupResult = .failure(CustomError.categoryNotFoundError)

        await #expect(throws: (any Error).self) {
            try await useCase.execute(data: Data())
        }

        let isCalled = await repository.restoreCalled
        #expect(!isCalled)
    }
}
