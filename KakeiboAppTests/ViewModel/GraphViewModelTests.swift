//
//  GraphViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("GraphViewModel のテスト")
struct GraphViewModelTests {

    private func makeSUT() async throws -> (GraphViewModel, TransactionStore, CategoryModel) {
        let container = PersistenceController(inMemory: true).container
        let categoryRepo = CategoryRepository(container: container)
        let transactionRepo = TransactionRepository(container: container)

        let categoryStore = CategoryStore(repository: categoryRepo, autoLoad: false)
        let transactionStore = TransactionStore(repository: transactionRepo)

        let dummyCategory = try CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await categoryStore.add(dummyCategory)

        let viewModel = GraphViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        return (viewModel, transactionStore, dummyCategory)
    }

    // MARK: - 集計・ソートのテスト

    @Test("categorySummaries が金額順（降順）に正しく集計され、totalAmount が計算されること")
    func categorySummariesAndTotalAmount() async throws {
        let (viewModel, transactionStore, category) = try await makeSUT()
        let now = Date()

        let t1 = try TransactionModel(
            id: UUID(),
            title: "スーパー",
            memo: "",
            amount: 3000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        let t2 = try TransactionModel(
            id: UUID(),
            title: "外食",
            memo: "",
            amount: 2000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )

        try await transactionStore.add(t1)
        try await transactionStore.add(t2)

        await viewModel.reload()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.categorySummaries.count == 1)
        #expect(viewModel.categorySummaries.first?.totalAmount == 5000)
        #expect(viewModel.totalAmount == 5000)
        #expect(viewModel.totalTitle == "支出合計")
    }

    // MARK: - ヘルパー・リセット処理のテスト

    @Test("findCategory / deleteTransaction / changeMonth / clearError の検証")
    func helperMethodsCoverage() async throws {
        let (viewModel, store, category) = try await makeSUT()
        let now = Date()

        #expect(viewModel.findCategory(id: category.id)?.id == category.id)

        let transaction = try TransactionModel(
            id: UUID(),
            title: "夕食",
            memo: "",
            amount: 2000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        try await store.add(transaction)

        await viewModel.deleteTransaction(transaction)
        #expect(viewModel.isLoading == false)

        let initialStart = viewModel.dateRange.start
        viewModel.changeMonth(by: 1)
        #expect(viewModel.dateRange.start != initialStart)

        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }

    @Test("resetDateRangeIfNeeded の判定分岐検証")
    func resetDateRangeIfNeeded() async throws {
        let (viewModel, _, _) = try await makeSUT()

        // 初期状態（デフォルトRange）かつ当月の場合はスキップ
        viewModel.resetDateRangeIfNeeded(now: Date())

        // 過去の日付を渡す
        let pastDate = Calendar.current.date(byAdding: .month, value: -2, to: Date())!
        viewModel.resetDateRangeIfNeeded(now: pastDate)
    }
}
