//
//  GraphViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import XCTest
import Combine
@testable import KakeiboApp

@MainActor
final class GraphViewModelTests: XCTestCase {
    private var categoryStore: MockCategoryStore!
    private var transactionStore: MockTransactionStore!
    private var viewModel: GraphViewModel!
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

    private func makeViewModel() -> GraphViewModel {
        GraphViewModel(categoryStore: categoryStore, transactionStore: transactionStore)
    }

    // MARK: - テストデータ生成

    private func makeCategory(
        name: String = "食費",
        type: TransactionType = .expense
    ) -> CategoryModel {
        CategoryModel.stub(name: name, type: type)
    }

    private func makeTransaction(
        amount: Double = 1000,
        date: Date = Date(),
        type: TransactionType = .expense,
        categoryId: UUID
    ) -> TransactionModel {
        TransactionModel(
            id: UUID(),
            title: "テスト",
            memo: "",
            amount: amount,
            date: date,
            createdAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: categoryId
        )
    }

    // MARK: - categorySummaries 正常系

    func test_categorySummaries_正しく集計される() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 500, categoryId: category.id),
            makeTransaction(amount: 300, categoryId: category.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "summaries computed")
        viewModel.$categorySummaries
            .first { !$0.isEmpty }
            .sink { summaries in
                XCTAssertEqual(summaries.count, 1)
                XCTAssertEqual(summaries.first?.categoryName, "食費")
                XCTAssertEqual(summaries.first?.totalAmount, 800)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_totalAmount降順でソートされる() async throws {
        let cat1 = makeCategory(name: "食費")
        let cat2 = makeCategory(name: "交通費")
        categoryStore.stubbedCategories = [cat1, cat2]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 300, categoryId: cat1.id),
            makeTransaction(amount: 1000, categoryId: cat2.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "sorted by amount")
        viewModel.$categorySummaries
            .first { $0.count == 2 }
            .sink { summaries in
                XCTAssertEqual(summaries.map(\.categoryName), ["交通費", "食費"])
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_合計が0のカテゴリは含まれない() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]
        transactionStore.stubbedTransactions = []
        viewModel = makeViewModel()

        let exp = expectation(description: "empty summaries")
        viewModel.$categorySummaries
            .first()
            .sink { summaries in
                XCTAssertTrue(summaries.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_selectedType変更で再集計される() async throws {
        let expenseCat = makeCategory(name: "食費", type: .expense)
        let incomeCat = makeCategory(name: "給与", type: .income)
        categoryStore.stubbedCategories = [expenseCat, incomeCat]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 1000, type: .expense, categoryId: expenseCat.id),
            makeTransaction(amount: 5000, type: .income, categoryId: incomeCat.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "income summaries")
        viewModel.$categorySummaries
            .first { $0.first?.categoryName == "給与" }
            .sink { summaries in
                XCTAssertEqual(summaries.first?.totalAmount, 5000)
                exp.fulfill()
            }
            .store(in: &cancellables)

        // 購読後に変更
        viewModel.selectedType = .income

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_dateRange変更で再集計される() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]

        let today = Date()
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 1000, date: today, categoryId: category.id),
            makeTransaction(amount: 2000, date: lastMonth, categoryId: category.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "last month summaries")
        viewModel.$categorySummaries
            .first { $0.first?.totalAmount == 2000 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        // 購読後に変更
        viewModel.dateRange = DateRange(
            start: lastMonth.startOfMonth,
            end: lastMonth.endOfMonth
        )

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_カテゴリに紐づかないトランザクションは集計されない() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 1000, categoryId: category.id),
            makeTransaction(amount: 500, categoryId: UUID()),  // 存在しないカテゴリID
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "unrelated excluded")
        viewModel.$categorySummaries
            .first { !$0.isEmpty }
            .sink { summaries in
                XCTAssertEqual(summaries.count, 1)
                XCTAssertEqual(summaries.first?.totalAmount, 1000)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - categorySummaries 境界値

    func test_categorySummaries_NaNのamountが除外される() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: Double.nan, categoryId: category.id),
            makeTransaction(amount: 1000, categoryId: category.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "NaN excluded")
        viewModel.$categorySummaries
            .first { !$0.isEmpty }
            .sink { summaries in
                XCTAssertEqual(summaries.first?.totalAmount, 1000)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_Infinityのamountが除外される() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: Double.infinity, categoryId: category.id),
            makeTransaction(amount: 500, categoryId: category.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "Infinity excluded")
        viewModel.$categorySummaries
            .first { !$0.isEmpty }
            .sink { summaries in
                XCTAssertEqual(summaries.first?.totalAmount, 500)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_categorySummaries_月の境界日のトランザクションが含まれる() async throws {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]

        let today = Date()
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 100, date: today.startOfMonth, categoryId: category.id),
            makeTransaction(amount: 200, date: today.endOfMonth, categoryId: category.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "boundary included")
        viewModel.$categorySummaries
            .first { $0.first?.totalAmount == 300 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - totalAmount / totalTitle

    func test_totalAmount_categorySummariesの合計が返る() async throws {
        let cat1 = makeCategory(name: "食費")
        let cat2 = makeCategory(name: "交通費")
        categoryStore.stubbedCategories = [cat1, cat2]
        transactionStore.stubbedTransactions = [
            makeTransaction(amount: 1000, categoryId: cat1.id),
            makeTransaction(amount: 500, categoryId: cat2.id),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "total amount")
        viewModel.$categorySummaries
            .first { $0.count == 2 }
            .sink { summaries in
                let total = summaries.reduce(0) { $0 + $1.totalAmount }
                XCTAssertEqual(total, 1500)
                exp.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_totalAmount_トランザクションが0件のとき0が返る() {
        viewModel = makeViewModel()
        XCTAssertEqual(viewModel.totalAmount, 0)
    }

    func test_totalTitle_支出のとき支出合計が返る() {
        viewModel = makeViewModel()
        viewModel.selectedType = .expense
        XCTAssertEqual(viewModel.totalTitle, "支出合計")
    }

    func test_totalTitle_収入のとき収入合計が返る() {
        viewModel = makeViewModel()
        viewModel.selectedType = .income
        XCTAssertEqual(viewModel.totalTitle, "収入合計")
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

    // MARK: - deleteTransaction

    func test_deleteTransaction_正常に削除される() async throws {
        let category = makeCategory()
        let transaction = makeTransaction(categoryId: category.id)
        transactionStore.stubbedTransactions = [transaction]
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(transaction)

        XCTAssertEqual(transactionStore.deleteCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_deleteTransaction_エラー時にerrorMessageがセットされる() async throws {
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(makeTransaction(categoryId: UUID()))

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("削除に失敗しました") == true)
    }

    func test_deleteTransaction_isLoadingがtrueからfalseに変化する() async throws {
        viewModel = makeViewModel()
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        await viewModel.deleteTransaction(makeTransaction(categoryId: UUID()))

        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertEqual(loadingStates.last, false)
    }

    // MARK: - reload / loadMore

    func test_reload_transactionStoreのreloadが呼ばれる() async throws {
        viewModel = makeViewModel()

        await viewModel.reload()

        XCTAssertEqual(transactionStore.reloadCallCount, 1)
    }

    func test_reload_isLoadingがtrueからfalseに変化する() async throws {
        viewModel = makeViewModel()
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        await viewModel.reload()

        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertEqual(loadingStates.last, false)
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
        await viewModel.deleteTransaction(makeTransaction(categoryId: UUID()))
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - findCategory

    func test_findCategory_存在するIDでカテゴリが返る() {
        let category = makeCategory(name: "食費")
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()

        let found = viewModel.findCategory(id: category.id)

        XCTAssertEqual(found?.id, category.id)
        XCTAssertEqual(found?.name, "食費")
    }

    func test_findCategory_存在しないIDでnilが返る() {
        categoryStore.stubbedCategories = [makeCategory()]
        viewModel = makeViewModel()

        let found = viewModel.findCategory(id: UUID())

        XCTAssertNil(found)
    }

    // MARK: - hasMoreData

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
}
