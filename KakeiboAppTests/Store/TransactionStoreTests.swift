//
//  TransactionStoreTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/11
//
//

import XCTest
import Combine
@testable import KakeiboApp

// MARK: - Mock Repository

final class MockTransactionRepository: TransactionRepositoryProtocol, @unchecked Sendable {
    // 呼び出し記録
    var fetchCallCount = 0
    var addCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var searchCallCount = 0
    var lastFetchOffset: Int?
    var lastFetchLimit: Int?

    // 注入するデータ・エラー
    var stubbedTransactions: [TransactionModel] = []
    var fetchError: Error?
    var addError: Error?
    var updateError: Error?
    var deleteError: Error?
    var searchError: Error?

    func fetch(
        from start: Date?,
        to end: Date?,
        limit: Int?,
        offset: Int?
    ) async throws -> [TransactionModel] {
        fetchCallCount += 1
        lastFetchOffset = offset
        lastFetchLimit = limit
        if let error = fetchError { throw error }

        let offset = offset ?? 0
        let limit = limit ?? stubbedTransactions.count
        let sliced = Array(stubbedTransactions.dropFirst(offset).prefix(limit))
        return sliced
    }

    func search(text: String?) async throws -> [TransactionModel] {
        searchCallCount += 1
        if let error = searchError { throw error }
        guard let text, !text.isEmpty else { return stubbedTransactions }
        return stubbedTransactions.filter {
            $0.title.contains(text) || ($0.memo).contains(text)
        }
    }

    func add(_ model: TransactionModel) async throws {
        addCallCount += 1
        if let error = addError { throw error }
        stubbedTransactions.append(model)
    }

    func update(_ model: TransactionModel) async throws {
        updateCallCount += 1
        if let error = updateError { throw error }
        if let index = stubbedTransactions.firstIndex(where: { $0.id == model.id }) {
            stubbedTransactions[index] = model
        }
    }

    func delete(_ model: TransactionModel) async throws {
        deleteCallCount += 1
        if let error = deleteError { throw error }
        stubbedTransactions.removeAll { $0.id == model.id }
    }
}

// MARK: - Test Helpers

extension TransactionModel {
    static func stub(
        id: UUID = UUID(),
        title: String = "テスト",
        amount: Double = 1000,
        date: Date = Date(),
        type: TransactionType = .expense,
        memo: String? = nil
    ) -> TransactionModel {
        TransactionModel(
            id: id,
            title: title,
            memo: memo ?? "",
            amount: amount,
            date: date,
            createAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: UUID()
        )
    }
}

// MARK: - TransactionStore Tests

@MainActor
final class TransactionStoreTests: XCTestCase {
    private var repository: MockTransactionRepository!
    private var store: TransactionStore!
    private var cancellables: Set<AnyCancellable>!

    // initialLimit と同じ値
    private let initialLimit = 100
    private let loadMoreLimit = 50

    override func setUp() async throws {
        try await super.setUp()
        repository = MockTransactionRepository()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        store = nil
        repository = nil
        try await super.tearDown()
    }

    private func makeStore() async throws -> TransactionStore {
        let store = TransactionStore(repository: repository)
        try await Task.sleep(nanoseconds: 100_000_000)
        return store
    }

    // MARK: - 正常系

    func test_init_fetchが呼ばれトランザクションが読み込まれる() async throws {
        repository.stubbedTransactions = [.stub(title: "食費"), .stub(title: "交通費")]
        store = try await makeStore()

        XCTAssertGreaterThanOrEqual(repository.fetchCallCount, 1)

        let exp = expectation(description: "transactions loaded")
        store.transactions
            .first { $0.count == 2 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_add_リポジトリに追加されreloadされる() async throws {
        store = try await makeStore()
        let transaction = TransactionModel.stub(title: "ランチ")

        try await store.add(transaction)

        XCTAssertEqual(repository.addCallCount, 1)
        XCTAssertTrue(repository.stubbedTransactions.contains { $0.id == transaction.id })
    }

    func test_update_リポジトリのトランザクションが更新される() async throws {
        let original = TransactionModel.stub(title: "食費", amount: 1000)
        repository.stubbedTransactions = [original]
        store = try await makeStore()

        let updated = TransactionModel(
            id: original.id,
            title: "外食日",
            memo: "",
            amount: 2000,
            date: original.date,
            createAt: original.createdAt,
            updatedAt: Date(),
            type: original.type,
            categoryId: original.categoryId
        )

        try await store.update(updated)

        XCTAssertEqual(repository.updateCallCount, 1)
        XCTAssertEqual(repository.stubbedTransactions.first?.amount, 2000)
    }

    func test_delete_リポジトリからトランザクションが削除される() async throws {
        let transaction = TransactionModel.stub()
        repository.stubbedTransactions = [transaction]
        store = try await makeStore()

        try await store.delete(transaction)

        XCTAssertEqual(repository.deleteCallCount, 1)
        XCTAssertTrue(repository.stubbedTransactions.isEmpty)
    }

    func test_search_テキストに一致するトランザクションが返る() async throws {
        repository.stubbedTransactions = [
            .stub(title: "ランチ"),
            .stub(title: "交通費"),
            .stub(title: "ランニングシューズ"),
        ]
        store = try await makeStore()

        let results = await store.search(text: "ラン")

        XCTAssertEqual(results.count, 2)
        XCTAssertTrue(results.allSatisfy { $0.title.contains("ラン") })
    }

    func test_search_nilで全件返る() async throws {
        repository.stubbedTransactions = [.stub(), .stub(), .stub()]
        store = try await makeStore()

        let results = await store.search(text: nil)

        XCTAssertEqual(results.count, 3)
    }

    func test_search_空文字で全件返る() async throws {
        repository.stubbedTransactions = [.stub(), .stub()]
        store = try await makeStore()

        let results = await store.search(text: "")

        XCTAssertEqual(results.count, 2)
    }

    // MARK: - loadMore

    func test_loadMore_追加データが既存に追記される() async throws {
        // 初回100件 + loadMore用50件
        let initial = (1...100).map { TransactionModel.stub(title: "初回\($0)") }
        let additional = (1...30).map { TransactionModel.stub(title: "追加\($0)") }
        repository.stubbedTransactions = initial + additional
        store = try await makeStore()

        await store.loadMore()

        let exp = expectation(description: "loadMore appended")
        store.transactions
            .first { $0.count == 130 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_loadMore_取得件数がlimit未満ならhasMoreDataがfalseになる() async throws {
        // initialLimit ちょうどのデータ → hasMoreData = true
        let initial = (1...100).map { TransactionModel.stub(title: "初回\($0)") }
        // loadMore で 49件取得（50件未満）→ hasMoreData = false
        let additional = (1...49).map { TransactionModel.stub(title: "追加\($0)") }
        repository.stubbedTransactions = initial + additional
        store = try await makeStore()

        await store.loadMore()

        let exp = expectation(description: "hasMoreData false")
        store.hasMoreData
            .first { !$0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_loadMore_重複データが追加されない() async throws {
        let shared = (1...100).map { TransactionModel.stub(title: "共通\($0)") }
        repository.stubbedTransactions = shared
        store = try await makeStore()

        // offset=100 で取得されるデータが0件 → 重複なし
        await store.loadMore()

        let exp = expectation(description: "no duplicates")
        store.transactions
            .first()
            .sink { transactions in
                let ids = transactions.map { $0.id }
                let uniqueIds = Set(ids)
                XCTAssertEqual(ids.count, uniqueIds.count)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_loadMore_hasMoreDataがfalseのとき実行されない() async throws {
        // initialLimit未満のデータ → reload後 hasMoreData = false
        repository.stubbedTransactions = [.stub()]
        store = try await makeStore()

        let fetchCountBeforeLoadMore = repository.fetchCallCount
        await store.loadMore()

        XCTAssertEqual(repository.fetchCallCount, fetchCountBeforeLoadMore)
    }

    // MARK: - reload

    func test_reload_データが再取得される() async throws {
        repository.stubbedTransactions = [.stub(title: "古いデータ")]
        store = try await makeStore()

        repository.stubbedTransactions = [.stub(title: "新しいデータ1"), .stub(title: "新しいデータ2")]
        await store.reload()

        let exp = expectation(description: "reloaded")
        store.transactions
            .first { $0.count == 2 }
            .sink { transactions in
                XCTAssertTrue(transactions.allSatisfy { $0.title.contains("新しいデータ") })
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_reload_initialLimit件ちょうどのときhasMoreDataがtrueになる() async throws {
        repository.stubbedTransactions = (1...100).map { TransactionModel.stub(title: "\($0)") }
        store = try await makeStore()

        let exp = expectation(description: "hasMoreData true")
        store.hasMoreData
            .first { $0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_reload_initialLimit未満のときhasMoreDataがfalseになる() async throws {
        repository.stubbedTransactions = (1...50).map { TransactionModel.stub(title: "\($0)") }
        store = try await makeStore()

        let exp = expectation(description: "hasMoreData false")
        store.hasMoreData
            .first { !$0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - 異常系

    func test_add_エラー時にthrowされる() async throws {
        store = try await makeStore()
        repository.addError = CustomError.transactionNotFoundError

        do {
            try await store.add(.stub())
            XCTFail("エラーがthrowされるべき")
        } catch {
            XCTAssertEqual(repository.addCallCount, 1)
        }
    }

    func test_update_エラー時にthrowされる() async throws {
        let transaction = TransactionModel.stub()
        repository.stubbedTransactions = [transaction]
        store = try await makeStore()
        repository.updateError = CustomError.transactionNotFoundError

        do {
            try await store.update(transaction)
            XCTFail("エラーがthrowされるべき")
        } catch {
            XCTAssertEqual(repository.updateCallCount, 1)
        }
    }

    func test_delete_エラー時にthrowされる() async throws {
        let transaction = TransactionModel.stub()
        repository.stubbedTransactions = [transaction]
        store = try await makeStore()
        repository.deleteError = CustomError.transactionNotFoundError

        do {
            try await store.delete(transaction)
            XCTFail("エラーがthrowされるべき")
        } catch {
            XCTAssertEqual(repository.deleteCallCount, 1)
        }
    }

    func test_search_エラー時に空配列が返る() async throws {
        store = try await makeStore()
        repository.searchError = CustomError.transactionNotFoundError

        let results = await store.search(text: "テスト")

        XCTAssertTrue(results.isEmpty)
    }

    func test_reload_エラー時に既存データが保持される() async throws {
        repository.stubbedTransactions = [.stub(title: "保持されるデータ")]
        store = try await makeStore()

        repository.fetchError = CustomError.transactionNotFoundError
        await store.reload()

        let exp = expectation(description: "data retained")
        store.transactions
            .first { $0.count == 1 }
            .sink { transactions in
                XCTAssertEqual(transactions.first?.title, "保持されるデータ")
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_loadMore_エラー時に既存データが保持される() async throws {
        let initial = (1...100).map { TransactionModel.stub(title: "初回\($0)") }
        repository.stubbedTransactions = initial
        store = try await makeStore()

        repository.fetchError = CustomError.transactionNotFoundError
        await store.loadMore()

        let exp = expectation(description: "data retained on loadMore error")
        store.transactions
            .first { $0.count == 100 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - 境界値

    func test_transactions_空のリポジトリで空配列が返る() async throws {
        repository.stubbedTransactions = []
        store = try await makeStore()

        let exp = expectation(description: "empty transactions")
        store.transactions
            .first()
            .sink { transactions in
                XCTAssertTrue(transactions.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_loadMore_空のデータが返ったときhasMoreDataがfalseになる() async throws {
        let initial = (1...100).map { TransactionModel.stub(title: "初回\($0)") }
        repository.stubbedTransactions = initial
        store = try await makeStore()

        // offset=100 以降は空 → loadMore で hasMoreData = false
        await store.loadMore()

        let exp = expectation(description: "hasMoreData false on empty loadMore")
        store.hasMoreData
            .first { !$0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_reload後_hasMoreDataがリセットされる() async throws {
        // まず全データ取得済み（hasMoreData = false）の状態にする
        repository.stubbedTransactions = (1...50).map { TransactionModel.stub(title: "\($0)") }
        store = try await makeStore()

        // 100件に増やして reload
        repository.stubbedTransactions = (1...100).map { TransactionModel.stub(title: "\($0)") }
        await store.reload()

        let exp = expectation(description: "hasMoreData reset to true after reload")
        store.hasMoreData
            .first { $0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_search_memoでも検索できる() async throws {
        repository.stubbedTransactions = [
            .stub(title: "食費", memo: "スーパーで購入"),
            .stub(title: "交通費", memo: nil),
        ]
        store = try await makeStore()

        let results = await store.search(text: "スーパー")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "食費")
    }
}
