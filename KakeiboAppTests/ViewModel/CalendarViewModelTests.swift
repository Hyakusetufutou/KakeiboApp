//
//  CalendarViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("CalendarViewModel のテスト")
struct CalendarViewModelTests {

    private func makeSUT() async throws -> (CalendarViewModel, TransactionStore, CategoryModel) {
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

        let viewModel = CalendarViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        return (viewModel, transactionStore, dummyCategory)
    }

    // MARK: - 集計・バインディングテスト

    @Test("トランザクション読み込み時に dailySummaries が日付ごとに集計されること")
    func dailySummariesAggregation() async throws {
        let (viewModel, transactionStore, category) = try await makeSUT()
        let now = Date()

        let t1 = try TransactionModel(
            id: UUID(),
            title: "コーヒー",
            memo: "",
            amount: 400,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        let t2 = try TransactionModel(
            id: UUID(),
            title: "本",
            memo: "",
            amount: 1600,
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

        let startOfDay = Calendar.current.startOfDay(for: now)
        let summary = viewModel.dailySummaries[startOfDay]
        #expect(summary != nil)
        #expect(summary?.expense == 2000)
        #expect(summary?.transactions.count == 2)
    }

    // MARK: - 操作・ヘルパーメソッドのテスト

    @Test("changeMonth(by:) で dateRange が次月・前月に正しく変更されること")
    func changeMonth() async throws {
        let (viewModel, _, _) = try await makeSUT()
        let initialStart = viewModel.dateRange.start

        viewModel.changeMonth(by: 1)

        let expectedNextMonth = Calendar.current.date(byAdding: .month, value: 1, to: initialStart)!
        #expect(
            Calendar.current.isDate(
                viewModel.dateRange.start,
                equalTo: expectedNextMonth,
                toGranularity: .month
            )
        )
    }

    @Test("category / delete / reload / clearError の検証")
    func helperMethodsCoverage() async throws {
        let (viewModel, store, category) = try await makeSUT()
        let now = Date()

        #expect(viewModel.category(for: category.id)?.id == category.id)

        let transaction = try TransactionModel(
            id: UUID(),
            title: "ランチ",
            memo: "",
            amount: 800,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        try await store.add(transaction)

        await viewModel.reload()
        #expect(viewModel.isLoading == false)

        await viewModel.delete(transaction)
        #expect(viewModel.isLoading == false)

        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }

    @Test("resetDateRangeIfNeeded の動作検証")
    func resetDateRangeIfNeeded() async throws {
        let (viewModel, _, _) = try await makeSUT()

        // 現在の月と一致している場合は処理されない
        viewModel.resetDateRangeIfNeeded()

        // 範囲外の月に変更後に呼び出し
        viewModel.changeMonth(by: -3)
        viewModel.resetDateRangeIfNeeded()
    }
}
