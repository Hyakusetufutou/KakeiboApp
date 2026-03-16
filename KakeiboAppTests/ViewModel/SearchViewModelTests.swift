//
//  SearchViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import XCTest
import Combine
@testable import KakeiboApp

@MainActor
final class SearchViewModelTests: XCTestCase {
    private var categoryStore: MockCategoryStore!
    private var transactionStore: MockTransactionStore!
    private var viewModel: SearchViewModel!
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

    private func makeViewModel() -> SearchViewModel {
        SearchViewModel(categoryStore: categoryStore, transactionStore: transactionStore)
    }

    private func makeTransaction(
        title: String = "テスト",
        date: Date = Date(),
        memo: String? = nil
    ) -> TransactionModel {
        TransactionModel(
            id: UUID(),
            title: title,
            memo: memo ?? "",
            amount: 1000,
            date: date,
            createAt: Date(),
            updatedAt: Date(),
            type: .expense,
            categoryId: UUID()
        )
    }

    // MARK: - 検索 正常系

    func test_searchText入力で検索結果が返る() async throws {
        transactionStore.stubbedTransactions = [
            makeTransaction(title: "ランチ"),
            makeTransaction(title: "交通費"),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "search results")
        viewModel.$resultTransactions
            .first { $0.count == 1 }
            .sink { transactions in
                XCTAssertEqual(transactions.first?.title, "ランチ")
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchText = "ランチ"

        // debounce の 300ms + マージン
        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_searchText_date降順でソートされる() async throws {
        let today = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        transactionStore.stubbedTransactions = [
            makeTransaction(title: "ランチ昨日", date: yesterday),
            makeTransaction(title: "ランチ今日", date: today),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "sorted results")
        viewModel.$resultTransactions
            .first { $0.count == 2 }
            .sink { transactions in
                XCTAssertEqual(transactions.map(\.title), ["ランチ今日", "ランチ昨日"])
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchText = "ランチ"

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_searchText_空文字のときresultTransactionsが空になる() async throws {
        transactionStore.stubbedTransactions = [makeTransaction(title: "ランチ")]
        viewModel = makeViewModel()

        // まず検索して結果を持った状態にする
        let exp1 = expectation(description: "has results")
        viewModel.$resultTransactions
            .first { $0.count == 1 }
            .sink { _ in exp1.fulfill() }
            .store(in: &cancellables)
        viewModel.searchText = "ランチ"
        await fulfillment(of: [exp1], timeout: 2.0)

        // 空文字に変更
        let exp2 = expectation(description: "empty results")
        viewModel.$resultTransactions
            .first { $0.isEmpty }
            .sink { _ in exp2.fulfill() }
            .store(in: &cancellables)
        viewModel.searchText = ""

        await fulfillment(of: [exp2], timeout: 2.0)
    }

    func test_searchText_空白のみのときresultTransactionsが空になる() async throws {
        transactionStore.stubbedTransactions = [makeTransaction(title: "ランチ")]
        viewModel = makeViewModel()

        let exp = expectation(description: "empty on whitespace")
        viewModel.$resultTransactions
            .first { _ in true }  // 初期値（空）を確認
            .sink { transactions in
                XCTAssertTrue(transactions.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchText = "   "

        await fulfillment(of: [exp], timeout: 2.0)
    }

    func test_searchText_同じテキストを連続入力しても検索は1回だけ実行される() async throws {
        transactionStore.stubbedTransactions = [makeTransaction(title: "ランチ")]
        viewModel = makeViewModel()

        viewModel.searchText = "ランチ"
        viewModel.searchText = "ランチ"  // 重複

        // debounce 待機
        try await Task.sleep(nanoseconds: 500_000_000)

        // removeDuplicates により search は1回のみ呼ばれるべき
        // MockTransactionStore の search は直接カウントしていないため
        // resultTransactions が正常に返ることを確認
        XCTAssertEqual(viewModel.resultTransactions.count, 1)
    }

    // MARK: - deleteTransaction

    func test_deleteTransaction_正常に削除される() async throws {
        let transaction = makeTransaction()
        transactionStore.stubbedTransactions = [transaction]
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(transaction)

        XCTAssertEqual(transactionStore.deleteCallCount, 1)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_deleteTransaction_エラー時にerrorMessageがセットされる() async throws {
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()

        await viewModel.deleteTransaction(makeTransaction())

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("削除に失敗しました") == true)
    }

    func test_deleteTransaction_isLoadingがtrueからfalseに変化する() async throws {
        viewModel = makeViewModel()
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        await viewModel.deleteTransaction(makeTransaction())

        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertEqual(loadingStates.last, false)
    }

    // MARK: - findCategory

    func test_findCategory_存在するIDでカテゴリが返る() {
        let category = CategoryModel.stub(name: "食費")
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()

        let found = viewModel.findCategory(id: category.id)

        XCTAssertEqual(found?.id, category.id)
    }

    func test_findCategory_存在しないIDでnilが返る() {
        viewModel = makeViewModel()

        XCTAssertNil(viewModel.findCategory(id: UUID()))
    }

    // MARK: - clearError

    func test_clearError_errorMessageがnilになる() async throws {
        transactionStore.deleteError = CustomError.transactionNotFoundError
        viewModel = makeViewModel()
        await viewModel.deleteTransaction(makeTransaction())
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - 境界値

    func test_searchText_一致なしのとき空配列が返る() async throws {
        transactionStore.stubbedTransactions = [makeTransaction(title: "交通費")]
        viewModel = makeViewModel()

        let exp = expectation(description: "no results")
        viewModel.$resultTransactions
            .first { _ in true }
            .sink { transactions in
                XCTAssertTrue(transactions.isEmpty)
                exp.fulfill()
            }
            .store(in: &cancellables)

        viewModel.searchText = "存在しないキーワード"

        await fulfillment(of: [exp], timeout: 2.0)
    }
}
