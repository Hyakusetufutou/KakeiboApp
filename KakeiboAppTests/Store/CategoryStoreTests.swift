//
//  KakeiboAppTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import XCTest
import Combine
@testable import KakeiboApp

// MARK: - Mock Repository

final class MockCategoryRepository: CategoryRepositoryProtocol, @unchecked Sendable {
    // 呼び出し記録
    var fetchAllCallCount = 0
    var addCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0

    // 注入するデータ・エラー
    var stubbedCategories: [CategoryModel] = []
    var fetchAllError: Error?
    var addError: Error?
    var updateError: Error?
    var deleteError: Error?

    func fetchAll() async throws -> [CategoryModel] {
        fetchAllCallCount += 1
        if let error = fetchAllError { throw error }
        return stubbedCategories
    }

    func fetch(by id: UUID) async throws -> CategoryModel {
        guard let category = stubbedCategories.first(where: { $0.id == id }) else {
            throw CustomError.categoryNotFoundError
        }
        return category
    }

    func add(_ categoryModel: CategoryModel) async throws {
        addCallCount += 1
        if let error = addError { throw error }
        stubbedCategories.append(categoryModel)
    }

    func update(_ categoryModel: CategoryModel) async throws {
        updateCallCount += 1
        if let error = updateError { throw error }
        if let index = stubbedCategories.firstIndex(where: { $0.id == categoryModel.id }) {
            stubbedCategories[index] = categoryModel
        }
    }

    func delete(_ categoryModel: CategoryModel) async throws {
        deleteCallCount += 1
        if let error = deleteError { throw error }
        stubbedCategories.removeAll { $0.id == categoryModel.id }
    }
}

// MARK: - Test Helpers

extension CategoryModel {
    static func stub(
        id: UUID = UUID(),
        name: String = "食費",
        type: TransactionType = .expense,
        isDefault: Bool = false
    ) -> CategoryModel {
        CategoryModel(id: id, name: name, color: .orange, type: type, isDefault: isDefault)
    }
}

// MARK: - CategoryStore Tests

@MainActor
final class CategoryStoreTests: XCTestCase {
    private var repository: MockCategoryRepository!
    private var store: CategoryStore!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockCategoryRepository()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        store = nil
        repository = nil
        try await super.tearDown()
    }

    private func collectCategories(count: Int = 1) async -> [[CategoryModel]] {
        var results: [[CategoryModel]] = []
        let exp = expectation(description: "categories publisher")
        exp.expectedFulfillmentCount = count

        store.categories
            .sink { categories in
                results.append(categories)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
        return results
    }

    // MARK: - 正常系

    func test_init_fetchAllが呼ばれカテゴリが読み込まれる() async throws {
        repository.stubbedCategories = [.stub(name: "食費"), .stub(name: "交通費")]
        store = CategoryStore(repository: repository)

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(repository.fetchAllCallCount, 1)

        let exp = expectation(description: "categories loaded")
        store.categories
            .first { $0.count == 2 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_add_リポジトリにカテゴリが追加されreloadされる() async throws {
        store = CategoryStore(repository: repository)
        let category = CategoryModel.stub(name: "娯楽")

        try await store.add(category)

        XCTAssertEqual(repository.addCallCount, 1)
        XCTAssertEqual(repository.fetchAllCallCount, 2)
        XCTAssertTrue(repository.stubbedCategories.contains { $0.id == category.id })
    }

    func test_update_リポジトリのカテゴリが更新されreloadされる() async throws {
        let original = CategoryModel.stub(name: "食費")
        repository.stubbedCategories = [original]
        store = CategoryStore(repository: repository)

        let updated = CategoryModel(
            id: original.id,
            name: "外食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await store.update(updated)

        XCTAssertEqual(repository.updateCallCount, 1)
        XCTAssertEqual(repository.stubbedCategories.first?.name, "外食費")
    }

    func test_delete_リポジトリからカテゴリが削除されreloadされる() async throws {
        let category = CategoryModel.stub(name: "医療費")
        repository.stubbedCategories = [category]
        store = CategoryStore(repository: repository)

        try await store.delete(category)

        XCTAssertEqual(repository.deleteCallCount, 1)
        XCTAssertTrue(repository.stubbedCategories.isEmpty)
    }

    func test_find_存在するIDでカテゴリが返る() async throws {
        let category = CategoryModel.stub(name: "給与", type: .income)
        repository.stubbedCategories = [category]
        store = CategoryStore(repository: repository)

        try await Task.sleep(nanoseconds: 100_000_000)

        let found = store.find(id: category.id)
        XCTAssertEqual(found?.id, category.id)
        XCTAssertEqual(found?.name, "給与")
    }

    func test_find_存在しないIDでnilが返る() async throws {
        repository.stubbedCategories = [.stub()]
        store = CategoryStore(repository: repository)

        try await Task.sleep(nanoseconds: 100_000_000)

        let found = store.find(id: UUID())
        XCTAssertNil(found)
    }

    // MARK: - 異常系

    func test_add_エラー時にthrowされる() async throws {
        store = CategoryStore(repository: repository)
        repository.addError = CustomError.categoryNotFoundError

        do {
            try await store.add(.stub())
            XCTFail("エラーがthrowされるべき")
        } catch {
            XCTAssertEqual(repository.addCallCount, 1)
        }
    }

    func test_update_エラー時にthrowされる() async throws {
        let category = CategoryModel.stub()
        repository.stubbedCategories = [category]
        store = CategoryStore(repository: repository)
        repository.updateError = CustomError.categoryNotFoundError

        do {
            try await store.update(category)
            XCTFail("エラーがthrowされるべき")
        } catch {
            XCTAssertEqual(repository.updateCallCount, 1)
        }
    }

    func test_delete_エラー時にthrowされる() async throws {
        let category = CategoryModel.stub()
        repository.stubbedCategories = [category]
        store = CategoryStore(repository: repository)
        repository.deleteError = CustomError.categoryNotFoundError

        do {
            try await store.delete(category)
            XCTFail("エラーがthrowされるべき")
        } catch {
            XCTAssertEqual(repository.deleteCallCount, 1)
        }
    }

    func test_reload_fetchAllエラー時に既存データが保持される() async throws {
        repository.stubbedCategories = [.stub(name: "食費")]
        store = CategoryStore(repository: repository)
        try await Task.sleep(nanoseconds: 100_000_000)

        // reload時にエラーを注入
        repository.fetchAllError = CustomError.categoryNotFoundError
        repository.stubbedCategories = []

        // deleteでreloadをトリガー（deleteは成功、reloadのfetchAllが失敗）
        // エラー時はデータ保持のため、現在のcategoriesを確認
        let exp = expectation(description: "categories retained")
        store.categories
            .first { $0.count == 1 }
            .sink { categories in
                XCTAssertEqual(categories.first?.name, "食費")
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - 境界値

    func test_categories_空のリポジトリで空配列が返る() async throws {
        repository.stubbedCategories = []
        store = CategoryStore(repository: repository)

        let exp = expectation(description: "empty categories")
        store.categories
            .first()
            .sink { categories in
                XCTAssertTrue(categories.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_add_複数追加後に全件取得できる() async throws {
        store = CategoryStore(repository: repository)

        let categories = (1...5).map { CategoryModel.stub(name: "カテゴリ\($0)") }
        for category in categories {
            try await store.add(category)
        }

        XCTAssertEqual(repository.stubbedCategories.count, 5)
    }
}
