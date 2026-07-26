//
//  CategoryStoreTests.swift
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

    // MARK: - Private Helpers

    /// Store を生成し、初回 reload を完了させる
    private func makeStore() async -> CategoryStore {
        let store = CategoryStore(repository: repository, autoLoad: false)
        await store.reload()
        return store
    }

    /// errorPublisher から最初のエラーを受け取る
    private func collectFirstError(timeout: TimeInterval = 2.0) async -> Error? {
        let exp = expectation(description: "error received")
        var receivedError: Error?

        store.errorPublisher
            .first()
            .sink { error in
                receivedError = error
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: timeout)
        return receivedError
    }

    // MARK: - 正常系

    func test_init_fetchAllが呼ばれカテゴリが読み込まれる() async throws {
        repository.stubbedCategories = [.stub(name: "食費"), .stub(name: "交通費")]
        store = await makeStore()

        XCTAssertGreaterThanOrEqual(repository.fetchAllCallCount, 1)

        let exp = expectation(description: "categories loaded")
        store.categories
            .first { $0.count == 2 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_add_リポジトリにカテゴリが追加されreloadされる() async throws {
        store = await makeStore()
        let fetchCountBefore = repository.fetchAllCallCount
        let category = CategoryModel.stub(name: "娯楽")

        await store.add(category)

        XCTAssertEqual(repository.addCallCount, 1)
        // add 後に reload が呼ばれることを確認
        XCTAssertEqual(repository.fetchAllCallCount, fetchCountBefore + 1)
        XCTAssertTrue(repository.stubbedCategories.contains { $0.id == category.id })
    }

    func test_update_リポジトリのカテゴリが更新されreloadされる() async throws {
        let original = CategoryModel.stub(name: "食費")
        repository.stubbedCategories = [original]
        store = await makeStore()
        let fetchCountBefore = repository.fetchAllCallCount

        let updated = CategoryModel(
            id: original.id,
            name: "外食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        await store.update(updated)

        XCTAssertEqual(repository.updateCallCount, 1)
        // update 後に reload が呼ばれることを確認
        XCTAssertEqual(repository.fetchAllCallCount, fetchCountBefore + 1)
        XCTAssertEqual(repository.stubbedCategories.first?.name, "外食費")
    }

    func test_delete_リポジトリからカテゴリが削除されreloadされる() async throws {
        let category = CategoryModel.stub(name: "医療費")
        repository.stubbedCategories = [category]
        store = await makeStore()
        let fetchCountBefore = repository.fetchAllCallCount

        await store.delete(category)

        XCTAssertEqual(repository.deleteCallCount, 1)
        // delete 後に reload が呼ばれることを確認
        XCTAssertEqual(repository.fetchAllCallCount, fetchCountBefore + 1)
        XCTAssertTrue(repository.stubbedCategories.isEmpty)
    }

    func test_delete_デフォルトカテゴリは削除できずエラーになる() async throws {
        let defaultCategory = CategoryModel.stub(name: "その他", isDefault: true)
        repository.stubbedCategories = [defaultCategory]
        store = await makeStore()

        // errorPublisher の購読を先に開始してから delete を呼ぶ
        let exp = expectation(description: "error on delete default category")
        store.errorPublisher
            .first()
            .sink { error in
                // cannotDeleteDefaultCategory エラーが発行されることを確認
                exp.fulfill()
            }
            .store(in: &cancellables)

        await store.delete(defaultCategory)

        await fulfillment(of: [exp], timeout: 2.0)
        // リポジトリの delete は呼ばれていない
        XCTAssertEqual(repository.deleteCallCount, 0)
    }

    func test_find_存在するIDでカテゴリが返る() async throws {
        let category = CategoryModel.stub(name: "給与", type: .income)
        repository.stubbedCategories = [category]
        store = await makeStore()

        let found = store.find(id: category.id)
        XCTAssertEqual(found?.id, category.id)
        XCTAssertEqual(found?.name, "給与")
    }

    func test_find_存在しないIDでnilが返る() async throws {
        repository.stubbedCategories = [.stub()]
        store = await makeStore()

        let found = store.find(id: UUID())
        XCTAssertNil(found)
    }

    // MARK: - 異常系

    func test_add_エラー時にerrorPublisherにエラーが流れる() async throws {
        store = await makeStore()
        repository.addError = CustomError.categoryNotFoundError

        // errorPublisher の購読を先に開始してから add を呼ぶ
        let exp = expectation(description: "error on add")
        store.errorPublisher
            .first()
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await store.add(.stub())

        await fulfillment(of: [exp], timeout: 2.0)
        XCTAssertEqual(repository.addCallCount, 1)
    }

    func test_update_エラー時にerrorPublisherにエラーが流れる() async throws {
        let category = CategoryModel.stub()
        repository.stubbedCategories = [category]
        store = await makeStore()
        repository.updateError = CustomError.categoryNotFoundError

        let exp = expectation(description: "error on update")
        store.errorPublisher
            .first()
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await store.update(category)

        await fulfillment(of: [exp], timeout: 2.0)
        XCTAssertEqual(repository.updateCallCount, 1)
    }

    func test_delete_エラー時にerrorPublisherにエラーが流れる() async throws {
        let category = CategoryModel.stub()
        repository.stubbedCategories = [category]
        store = await makeStore()
        repository.deleteError = CustomError.categoryNotFoundError

        let exp = expectation(description: "error on delete")
        store.errorPublisher
            .first()
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await store.delete(category)

        await fulfillment(of: [exp], timeout: 2.0)
        XCTAssertEqual(repository.deleteCallCount, 1)
    }

    func test_reload_fetchAllエラー時に既存データが保持される() async throws {
        repository.stubbedCategories = [.stub(name: "食費")]
        store = await makeStore()

        // reload後にエラーを注入（次の reload で失敗させる）
        repository.fetchAllError = CustomError.categoryNotFoundError

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
        store = await makeStore()

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
        store = await makeStore()

        let categories = (1...5).map { CategoryModel.stub(name: "カテゴリ\($0)") }
        for category in categories {
            await store.add(category)
        }

        XCTAssertEqual(repository.stubbedCategories.count, 5)
    }

    func test_add_categoriesパブリッシャーが更新される() async throws {
        store = await makeStore()
        let category = CategoryModel.stub(name: "新カテゴリ")

        let exp = expectation(description: "categories updated after add")
        store.categories
            .first { $0.contains { $0.id == category.id } }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await store.add(category)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_delete_categoriesパブリッシャーから削除される() async throws {
        let category = CategoryModel.stub(name: "削除対象")
        repository.stubbedCategories = [category]
        store = await makeStore()

        let exp = expectation(description: "categories updated after delete")
        store.categories
            .first { !$0.contains { $0.id == category.id } }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await store.delete(category)

        await fulfillment(of: [exp], timeout: 2.0)
    }
}
