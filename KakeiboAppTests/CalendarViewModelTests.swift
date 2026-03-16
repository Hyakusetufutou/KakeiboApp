//
//  CalendarViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import XCTest
import Combine
@testable import KakeiboApp

@MainActor
final class CalendarViewModelTests: XCTestCase {
    private var categoryStore: MockCategoryStore!
    private var transactionStore: MockTransactionStore!
    private var viewModel: CalendarViewModel!
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

    private func makeViewModel() -> CalendarViewModel {
        CalendarViewModel(categoryStore: categoryStore, transactionStore: transactionStore)
    }

    private func makeTransaction(
        amount: Double = 1000,
        date: Date = Date(),
        type: TransactionType = .expense,
        categoryId: UUID = UUID()
    ) -> TransactionModel {
        TransactionModel(
            id: UUID(),
            title: "テスト",
            memo: "",
            amount: amount,
            date: date,
            createAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: categoryId
        )
    }

    // MARK: - dailySummaries 正常系

    func test_dailySummaries_支出と収入が正しく集計される() async throws {
        let today = Date()
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 1000, date: today, type: .expense),
            makeTransaction(amount: 500, date: today, type: .expense),
            makeTransaction(amount: 3000, date: today, type: .income),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "daily summaries computed")
        viewModel.$dailySummaries
            .first { !$0.isEmpty }
            .sink { summaries in
                let key = Calendar.current.startOfDay(for: today)
                let summary = summaries[key]
                XCTAssertNotNil(summary)
                XCTAssertEqual(summary?.expense, 1500)
                XCTAssertEqual(summary?.income, 3000)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_dailySummaries_日付ごとにグループ化される() async throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        transactionStore.stubbedTransactions = [
            makeTransaction(date: today),
            makeTransaction(date: yesterday),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "grouped by day")
        viewModel.$dailySummaries
            .first { $0.count == 2 }
            .sink { summaries in
                XCTAssertEqual(summaries.count, 2)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_dailySummaries_dateRange外のトランザクションは含まれない() async throws {
        let today = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
        transactionStore.stubbedTransactions = [
            makeTransaction(date: today),
            makeTransaction(date: lastMonth),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "filtered by dateRange")
        viewModel.$dailySummaries
            .first { !$0.isEmpty }
            .sink { summaries in
                XCTAssertEqual(summaries.count, 1)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_dailySummaries_dateRange変更で再集計される() async throws {
        let today = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 1000, date: today),
            makeTransaction(amount: 2000, date: lastMonth),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "recomputed after dateRange change")
        viewModel.$dailySummaries
            .first { summaries in
                let key = Calendar.current.startOfDay(for: lastMonth)
                return summaries[key] != nil
            }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        // 購読後に変更
        viewModel.dateRange = DateRange(
            start: lastMonth.startOfMonth,
            end: lastMonth.endOfMonth
        )

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_dailySummaries_トランザクションが0件のとき空辞書が返る() async throws {
        transactionStore.stubbedTransactions = []
        viewModel = makeViewModel()

        let exp = expectation(description: "empty summaries")
        viewModel.$dailySummaries
            .first()
            .sink { summaries in
                XCTAssertTrue(summaries.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - changeMonth

    func test_changeMonth_1加算で翌月に変わる() {
        viewModel = makeViewModel()
        let original = viewModel.dateRange.start

        viewModel.changeMonth(by: 1)

        let expected = Calendar.current.date(byAdding: .month, value: 1, to: original)!
        XCTAssertTrue(
            Calendar.current.isDate(
                viewModel.dateRange.start,
                equalTo: expected,
                toGranularity: .month
            )
        )
    }

    func test_changeMonth_マイナス1で先月に変わる() {
        viewModel = makeViewModel()
        let original = viewModel.dateRange.start

        viewModel.changeMonth(by: -1)

        let expected = Calendar.current.date(byAdding: .month, value: -1, to: original)!
        XCTAssertTrue(
            Calendar.current.isDate(
                viewModel.dateRange.start,
                equalTo: expected,
                toGranularity: .month
            )
        )
    }

    func test_changeMonth_startOfMonthとendOfMonthが正しく設定される() {
        viewModel = makeViewModel()

        viewModel.changeMonth(by: 1)

        XCTAssertEqual(viewModel.dateRange.start, viewModel.dateRange.start.startOfMonth)
        XCTAssertEqual(viewModel.dateRange.end, viewModel.dateRange.end.endOfMonth)
    }

    // MARK: - delete

    func test_delete_正常に削除される() async throws {
        let transaction = makeTransaction()
        transactionStore.stubbedTransactions = [transaction]
        viewModel = makeViewModel()

        await viewModel.delete(transaction)

        XCTAssertEqual(transactionStore.deleteCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_delete_エラー時にerrorMessageがセットされる() async throws {
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()

        await viewModel.delete(makeTransaction())

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("削除に失敗しました") == true)
    }

    func test_delete_isLoadingがtrueからfalseに変化する() async throws {
        viewModel = makeViewModel()
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        await viewModel.delete(makeTransaction())

        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertEqual(loadingStates.last, false)
    }

    // MARK: - category(for:)

    func test_categoryFor_存在するIDでカテゴリが返る() {
        let category = CategoryModel.stub(name: "食費")
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()

        let found = viewModel.category(for: category.id)

        XCTAssertEqual(found?.id, category.id)
    }

    func test_categoryFor_存在しないIDでnilが返る() {
        categoryStore.stubbedCategories = [.stub()]
        viewModel = makeViewModel()

        XCTAssertNil(viewModel.category(for: UUID()))
    }

    // MARK: - reload / loadMore

    func test_reload_transactionStoreのreloadが呼ばれる() async throws {
        viewModel = makeViewModel()

        await viewModel.reload()

        XCTAssertEqual(transactionStore.reloadCallCount, 1)
    }

    func test_loadMore_hasMoreDataがtrueのときloadMoreが呼ばれる() async throws {
        transactionStore.stubbedHasMoreData = true
        viewModel = makeViewModel()

        await viewModel.loadMore()

        XCTAssertEqual(transactionStore.loadMoreCallCount, 1)
    }

    func test_loadMore_hasMoreDataがfalseのときloadMoreが呼ばれない() async throws {
        transactionStore.stubbedHasMoreData = false
        viewModel = makeViewModel()

        let exp = expectation(description: "hasMoreData false")
        viewModel.$hasMoreData
            .first { !$0 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp], timeout: 2.0)

        await viewModel.loadMore()

        XCTAssertEqual(transactionStore.loadMoreCallCount, 0)
    }

    // MARK: - clearError

    func test_clearError_errorMessageがnilになる() async throws {
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()
        await viewModel.delete(makeTransaction())
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - resetDateRangeIfNeeded

    func test_resetDateRangeIfNeeded_今月表示中は変更されない() {
        viewModel = makeViewModel()
        let originalRange = viewModel.dateRange

        viewModel.resetDateRangeIfNeeded()

        XCTAssertEqual(viewModel.dateRange.start, originalRange.start)
        XCTAssertEqual(viewModel.dateRange.end, originalRange.end)
    }

    func test_resetDateRangeIfNeeded_別月表示中は今月にリセットされる() {
        viewModel = makeViewModel()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        viewModel.dateRange = DateRange(start: lastMonth.startOfMonth, end: lastMonth.endOfMonth)

        viewModel.resetDateRangeIfNeeded()

        XCTAssertTrue(
            Calendar.current.isDate(
                viewModel.dateRange.start,
                equalTo: Date().startOfMonth,
                toGranularity: .day
            )
        )
    }

    // MARK: - 境界値

    func test_dailySummaries_月の境界日のトランザクションが含まれる() async throws {
        let today = Date()
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 100, date: today.startOfMonth),
            makeTransaction(amount: 200, date: today.endOfMonth),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "boundary dates included")
        viewModel.$dailySummaries
            .first { $0.count == 2 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }
}
