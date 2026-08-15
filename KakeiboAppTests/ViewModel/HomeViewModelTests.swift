//
//  HomeViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/12
//
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("HomeViewModel のテスト")
struct HomeViewModelTests {

    private func makeSUT() async throws -> (HomeViewModel, TransactionStore, CategoryModel) {
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

        let viewModel = HomeViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        return (viewModel, transactionStore, dummyCategory)
    }

    // MARK: - バインディング・計算プロパティのテスト

    @Test("selectedType や dateRange の変更により filteredTransactions と transactionSummary が計算されること")
    func filteredTransactionsAndSummaryCalculation() async throws {
        let (viewModel, transactionStore, category) = try await makeSUT()
        let now = Date()

        let expenseTransaction = TransactionModel(
            id: UUID(),
            title: "ランチ",
            memo: "",
            amount: 1000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        let incomeTransaction = TransactionModel(
            id: UUID(),
            title: "給料",
            memo: "",
            amount: 50000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .income,
            categoryId: category.id
        )

        try await transactionStore.add(expenseTransaction)
        try await transactionStore.add(incomeTransaction)

        // ロードして反映を待つ
        await viewModel.reload()
        try await Task.sleep(nanoseconds: 50_000_000)

        // 初期状態 (selectedType = .expense)
        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.title == "ランチ")
        #expect(viewModel.transactionSummary.expense == 1000)
        #expect(viewModel.transactionSummary.income == 50000)

        // selectedType を .income に切り替え
        viewModel.selectedType = .income
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.filteredTransactions.count == 1)
        #expect(viewModel.filteredTransactions.first?.title == "給料")
    }

    // MARK: - アクション・ヘルパーメソッドのテスト

    @Test("findCategory / deleteTransaction / clearError の検証")
    func findCategoryAndDeleteAndClearError() async throws {
        let (viewModel, store, category) = try await makeSUT()
        let now = Date()

        #expect(viewModel.findCategory(id: category.id)?.id == category.id)
        #expect(viewModel.findCategory(id: UUID()) == nil)

        let transaction = TransactionModel(
            id: UUID(),
            title: "カフェ",
            memo: "",
            amount: 500,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        try await store.add(transaction)

        await viewModel.deleteTransaction(transaction)
        #expect(viewModel.isLoading == false)

        viewModel.errorMessage = "テストエラー"
        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }

    @Test("resetDateRangeIfNeeded の日付分岐のテスト")
    func resetDateRangeIfNeeded() async throws {
        let (viewModel, _, _) = try await makeSUT()

        // 1. 同年月の場合 -> スキップされる
        viewModel.resetDateRangeIfNeeded(now: Date())

        // 2. 過去月を渡した場合 -> reset される
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        viewModel.resetDateRangeIfNeeded(now: pastDate)
    }
}
