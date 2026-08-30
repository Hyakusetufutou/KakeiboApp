//
//  SettingViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/29
//
//

import Foundation
import Combine
import Testing
@testable import KakeiboApp

// MARK: - Mocks

final class MockCreateBackupUseCase: CreateBackupUseCaseProtocol, @unchecked Sendable {
    var result: Result<Data, Error> = .failure(CustomError.categoryNotFoundError)

    func execute() async throws -> Data {
        try result.get()
    }
}

final class MockRestoreBackupUseCase: RestoreBackupUseCaseProtocol, @unchecked Sendable {
    var result: Result<Void, Error> = .success(())
    private(set) var passedData: Data?

    func execute(data: Data) async throws {
        passedData = data
        try result.get()
    }
}

@MainActor
final class MockCategoryStore: CategoryStoreProtocol {
    @Published var categoriesSubject: [CategoryModel] = []
    private let errorSubject = PassthroughSubject<Error, Never>()

    var categories: AnyPublisher<[CategoryModel], Never> {
        $categoriesSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    private(set) var reloadCalled = false

    func reload() async {
        reloadCalled = true
    }

    func find(id: UUID) -> CategoryModel? {
        categoriesSubject.first { $0.id == id }
    }

    func add(_ category: CategoryModel) async throws {}
    func update(_ category: CategoryModel) async throws {}
    func delete(_ category: CategoryModel) async throws {}
}

@MainActor
final class MockTransactionStore: TransactionStoreProtocol {
    @Published var transactionsSubject: [TransactionModel] = []
    private let errorSubject = PassthroughSubject<Error, Never>()

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $transactionsSubject.eraseToAnyPublisher()
    }

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    private(set) var loadCalled = false
    private(set) var loadWithRangeCalled = false

    func load(from start: Date, to end: Date) async throws {
        loadWithRangeCalled = true
    }

    func load() async {
        loadCalled = true
    }

    func add(_ transaction: TransactionModel) async throws {}
    func update(_ transaction: TransactionModel) async throws {}
    func delete(_ transaction: TransactionModel) async throws {}
    func search(text: String?) async throws -> [TransactionModel] { [] }
}

// MARK: - SettingViewModel Tests

@MainActor
@Suite("SettingViewModel Tests")
struct SettingViewModelTests {

    // MARK: - createBackup Tests

    @Test("createBackup 正常系: バックアップデータの作成に成功し Data が返却されること")
    func testCreateBackupSuccess() async {
        let createUseCase = MockCreateBackupUseCase()
        let restoreUseCase = MockRestoreBackupUseCase()
        let categoryStore = MockCategoryStore()
        let transactionStore = MockTransactionStore()

        let expectedData = "testBackupData".data(using: .utf8)!
        createUseCase.result = .success(expectedData)

        let viewModel = SettingViewModel(
            createBackupUseCase: createUseCase,
            restoreBackupUseCase: restoreUseCase,
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )

        let result = await viewModel.createBackup()

        #expect(result == expectedData)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isProcessing == false)
    }

    @Test("createBackup 異常系: エラー時に errorMessage がセットされ nil が返却されること")
    func testCreateBackupFailure() async {
        let createUseCase = MockCreateBackupUseCase()
        let restoreUseCase = MockRestoreBackupUseCase()
        let categoryStore = MockCategoryStore()
        let transactionStore = MockTransactionStore()

        createUseCase.result = .failure(CustomError.categoryNotFoundError)

        let viewModel = SettingViewModel(
            createBackupUseCase: createUseCase,
            restoreBackupUseCase: restoreUseCase,
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )

        let result = await viewModel.createBackup()

        #expect(result == nil)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isProcessing == false)
    }

    // MARK: - restoreBackup Tests

    @Test("restoreBackup 正常系: 復元が成功し Store の再読み込みが行われること")
    func testRestoreBackupSuccess() async {
        let createUseCase = MockCreateBackupUseCase()
        let restoreUseCase = MockRestoreBackupUseCase()
        let categoryStore = MockCategoryStore()
        let transactionStore = MockTransactionStore()

        restoreUseCase.result = .success(())

        let viewModel = SettingViewModel(
            createBackupUseCase: createUseCase,
            restoreBackupUseCase: restoreUseCase,
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )

        let dummyData = "restoreData".data(using: .utf8)!
        await viewModel.restoreBackup(from: dummyData)

        #expect(restoreUseCase.passedData == dummyData)
        #expect(transactionStore.loadCalled == true)
        #expect(categoryStore.reloadCalled == true)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isProcessing == false)
    }

    @Test("restoreBackup 異常系: 復元失敗時に errorMessage がセットされ Store の再読み込みが呼ばれないこと")
    func testRestoreBackupFailure() async {
        let createUseCase = MockCreateBackupUseCase()
        let restoreUseCase = MockRestoreBackupUseCase()
        let categoryStore = MockCategoryStore()
        let transactionStore = MockTransactionStore()

        restoreUseCase.result = .failure(CustomError.categoryNotFoundError)

        let viewModel = SettingViewModel(
            createBackupUseCase: createUseCase,
            restoreBackupUseCase: restoreUseCase,
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )

        let dummyData = "restoreData".data(using: .utf8)!
        await viewModel.restoreBackup(from: dummyData)

        #expect(restoreUseCase.passedData == dummyData)
        #expect(transactionStore.loadCalled == false)
        #expect(categoryStore.reloadCalled == false)
        #expect(viewModel.errorMessage != nil)
        #expect(viewModel.isProcessing == false)
    }
}
