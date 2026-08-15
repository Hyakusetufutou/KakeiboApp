//
//  SearchViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("SearchViewModel のテスト")
struct SearchViewModelTests {

    private func makeSUT() async throws -> (SearchViewModel, TransactionStore, CategoryModel) {
        let container = PersistenceController(inMemory: true).container
        let categoryRepo = CategoryRepository(container: container)
        let transactionRepo = TransactionRepository(container: container)

        let categoryStore = CategoryStore(repository: categoryRepo, autoLoad: false)
        let transactionStore = TransactionStore(repository: transactionRepo)

        let dummyCategory = CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await categoryStore.add(dummyCategory)

        let viewModel = SearchViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        return (viewModel, transactionStore, dummyCategory)
    }

    // MARK: - 検索機能（Debounce・クリア・キャンセル）のテスト

    @Test("searchText の入力後 debounce(300ms) を経て検索結果が更新されること")
    func searchDebounceAndResultUpdate() async throws {
        let (viewModel, transactionStore, category) = try await makeSUT()
        let now = Date()

        let transaction = TransactionModel(
            id: UUID(),
            title: "本屋で専門書購入",
            memo: "Swift本",
            amount: 3000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        try await transactionStore.add(transaction)

        viewModel.searchText = "専門書"

        // debounce (300ms) + 非同期実行待機
        try await Task.sleep(nanoseconds: 500_000_000)

        #expect(viewModel.resultTransactions.count == 1)
        #expect(viewModel.resultTransactions.first?.title == "本屋で専門書購入")
    }

    @Test("searchText を空文字に戻すと検索結果がクリアされること")
    func emptySearchTextClearsResults() async throws {
        let (viewModel, _, _) = try await makeSUT()

        viewModel.searchText = ""
        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(viewModel.resultTransactions.isEmpty)
    }

    @Test("連続した入力変更（Debounce とタスクキャンセルの挙動）の検証")
    func searchDebounceAndCancellation() async throws {
        let (viewModel, _, _) = try await makeSUT()

        // 高速で連続変更（前のタスクがキャンセルされる挙動をカバー）
        viewModel.searchText = "あ"
        viewModel.searchText = "あい"
        viewModel.searchText = "あいう"

        try await Task.sleep(nanoseconds: 400_000_000)

        #expect(viewModel.searchText == "あいう")
    }

    // MARK: - 操作・ヘルパーメソッドのテスト

    @Test("deleteTransaction / findCategory / clearError の検証")
    func helperMethodsCoverage() async throws {
        let (viewModel, store, category) = try await makeSUT()
        let now = Date()

        #expect(viewModel.findCategory(id: category.id)?.id == category.id)

        let transaction = TransactionModel(
            id: UUID(),
            title: "本",
            memo: "",
            amount: 1500,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        try await store.add(transaction)

        await viewModel.deleteTransaction(transaction)
        #expect(viewModel.isLoading == false)

        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}
