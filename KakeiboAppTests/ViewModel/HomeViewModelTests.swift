//
//  HomeViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/12
//
//

import XCTest
import Combine
@testable import KakeiboApp

@MainActor
final class HomeViewModelTests: XCTestCase {
    private var categoryStore: MockCategoryStore!
    private var transactionStore: MockTransactionStore!
    private var viewModel: HomeViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        categoryStore = MockCategoryStore()
        transactionStore = MockTransactionStore()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        transactionStore = nil
        categoryStore = nil
        try await super.tearDown()
    }

    private func makeViewModel() -> HomeViewModel {
        HomeViewModel(categoryStore: categoryStore, transactionStore: transactionStore)
    }

    // MARK: - テストデータ生成

    private func makeTransaction(
        title: String = "テスト",
        amount: Double = 1000,
        date: Date = Date(),
        type: TransactionType = .expense,
        categoryId: UUID = UUID()
    ) -> TransactionModel {
        TransactionModel(
            id: UUID(),
            title: title,
            memo: "",
            amount: amount,
            date: date,
            createdAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: categoryId
        )
    }

    // MARK: - 正常系

    func test_init_filteredTransactionsが今月・支出でフィルタされる() async throws {
        let today = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!

        transactionStore.stubbedTransactions = [
            makeTransaction(title: "今月支出", date: today, type: .expense),
            makeTransaction(title: "先月支出", date: lastMonth, type: .expense),
            makeTransaction(title: "今月収入", date: today, type: .income),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "filtered")
        viewModel.$filteredTransactions
            .first { $0.count == 1 }
            .sink { transactions in
                XCTAssertEqual(transactions.first?.title, "今月支出")
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_filteredTransactions_date降順でソートされる() async throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        transactionStore.stubbedTransactions = [
            makeTransaction(title: "昨日", date: yesterday, type: .expense),
            makeTransaction(title: "今日", date: today, type: .expense),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "sorted")
        viewModel.$filteredTransactions
            .first { $0.count == 2 }
            .sink { transactions in
                XCTAssertEqual(transactions.map(\.title), ["今日", "昨日"])
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_selectedTypeを変更するとfilteredTransactionsが更新される() async throws {
        let today = Date()
        transactionStore.stubbedTransactions = [
            makeTransaction(title: "支出", date: today, type: .expense),
            makeTransaction(title: "収入", date: today, type: .income),
        ]
        viewModel = makeViewModel()

        // 初期状態（支出）を確認
        let exp1 = expectation(description: "expense")
        viewModel.$filteredTransactions
            .first { $0.count == 1 && $0.first?.type == .expense }
            .sink { _ in exp1.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp1], timeout: 2.0)

        // 収入に切り替え
        viewModel.selectedType = .income

        let exp2 = expectation(description: "income")
        viewModel.$filteredTransactions
            .first { $0.count == 1 && $0.first?.type == .income }
            .sink { _ in exp2.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp2], timeout: 2.0)
    }

    func test_dateRangeを変更するとfilteredTransactionsが更新される() async throws {
        let calendar = Calendar.current
        let today = Date()
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!

        transactionStore.stubbedTransactions = [
            makeTransaction(title: "今月", date: today, type: .expense),
            makeTransaction(title: "先月", date: lastMonth, type: .expense),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "last month")

        // ✅ 先に購読してから dateRange を変更する
        viewModel.$filteredTransactions
            .first { $0.count == 1 && $0.first?.title == "先月" }  // タイトルも条件に加える
            .sink { transactions in
                XCTAssertEqual(transactions.first?.title, "先月")
                exp.fulfill()
            }
            .store(in: &cancellables)

        // 購読後に変更
        viewModel.dateRange = DateRange(
            start: lastMonth.startOfMonth,
            end: lastMonth.endOfMonth
        )

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categoryFind_存在するIDでカテゴリが返る() {
        let category = CategoryModel.stub(name: "食費")
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()

        let found = viewModel.findCategory(id: category.id)

        XCTAssertEqual(found?.id, category.id)
    }

    func test_categoryFind_存在しないIDでnilが返る() {
        categoryStore.stubbedCategories = [.stub()]
        viewModel = makeViewModel()

        let found = viewModel.findCategory(id: UUID())

        XCTAssertNil(found)
    }

    func test_deleteTransaction_正常に削除される() async throws {
        let transaction = makeTransaction()
        transactionStore.stubbedTransactions = [transaction]
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(transaction)

        XCTAssertEqual(transactionStore.deleteCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_reload_transactionStoreのreloadが呼ばれる() async throws {
        viewModel = makeViewModel()

        await viewModel.reload()

        XCTAssertEqual(transactionStore.reloadCallCount, 1)
    }

    func test_loadMore_hasMoreDataがtrueのときtransactionStoreのloadMoreが呼ばれる() async throws {
        transactionStore.stubbedHasMoreData = true
        viewModel = makeViewModel()

        await viewModel.loadMore()

        XCTAssertEqual(transactionStore.loadMoreCallCount, 1)
    }

    func test_clearError_errorMessageがnilになる() {
        viewModel = makeViewModel()
        viewModel.errorMessage = "エラー"

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    func test_hasMoreData_transactionStoreの値が反映される() async throws {
        transactionStore.stubbedHasMoreData = true
        viewModel = makeViewModel()

        transactionStore.stubbedHasMoreData = false

        let exp = expectation(description: "hasMoreData false")
        viewModel.$hasMoreData
            .first { !$0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - 異常系

    func test_deleteTransaction_エラー時にerrorMessageがセットされる() async throws {
        let transaction = makeTransaction()
        transactionStore.stubbedTransactions = [transaction]
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(transaction)

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("削除に失敗しました") == true)
    }

    func test_deleteTransaction_エラー後にclearErrorでnilになる() async throws {
        let transaction = makeTransaction()
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(transaction)
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - 境界値

    func test_filteredTransactions_データが0件のとき空配列が返る() async throws {
        transactionStore.stubbedTransactions = []
        viewModel = makeViewModel()

        let exp = expectation(description: "empty")
        viewModel.$filteredTransactions
            .first()
            .sink { transactions in
                XCTAssertTrue(transactions.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_loadMore_hasMoreDataがfalseのときloadMoreが呼ばれない() async throws {
        transactionStore.stubbedHasMoreData = false
        viewModel = makeViewModel()

        // hasMoreData の反映を待つ
        let exp = expectation(description: "hasMoreData false")
        viewModel.$hasMoreData
            .first { !$0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp], timeout: 2.0)

        await viewModel.loadMore()

        XCTAssertEqual(transactionStore.loadMoreCallCount, 0)
    }

    func test_filteredTransactions_月の境界日が含まれる() async throws {
        let today = Date()
        let startOfMonth = today.startOfMonth
        let endOfMonth = today.endOfMonth

        transactionStore.stubbedTransactions = [
            makeTransaction(title: "月初", date: startOfMonth, type: .expense),
            makeTransaction(title: "月末", date: endOfMonth, type: .expense),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "boundary dates included")
        viewModel.$filteredTransactions
            .first { $0.count == 2 }
            .sink { transactions in
                XCTAssertTrue(transactions.contains { $0.title == "月初" })
                XCTAssertTrue(transactions.contains { $0.title == "月末" })
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - resetDateRangeIfNeeded

    func test_resetDateRangeIfNeeded_今月表示中は変更されない() {
        viewModel = makeViewModel()
        let originalRange = viewModel.dateRange

        viewModel.resetDateRangeIfNeeded()

        XCTAssertEqual(viewModel.dateRange.start, originalRange.start)
        XCTAssertEqual(viewModel.dateRange.end, originalRange.end)
    }

    func test_resetDateRangeIfNeeded_カスタム期間は変更されない() {
        viewModel = makeViewModel()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        let customRange = DateRange(start: lastMonth.startOfMonth, end: lastMonth.endOfMonth)
        viewModel.dateRange = customRange

        viewModel.resetDateRangeIfNeeded()

        // カスタム期間なので変更されないことを確認
        XCTAssertEqual(viewModel.dateRange.start, customRange.start)
        XCTAssertEqual(viewModel.dateRange.end, customRange.end)
    }
}
