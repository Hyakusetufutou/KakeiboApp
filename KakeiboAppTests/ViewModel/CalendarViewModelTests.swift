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

    @Test("goToToday() で currentDate、selectedDate、dateRange が当日にリセットされること")
    func goToToday() async throws {
        let (viewModel, _, _) = try await makeSUT()

        // 事前準備: 意図的に別の月に変更しておく
        viewModel.changeMonth(by: -2)
        viewModel.selectedDate = nil

        // 実行
        viewModel.goToToday()

        // 検証: 今日の日付と一致していること
        let today = Date()
        let calendar = Calendar.current

        #expect(viewModel.selectedDate != nil)
        if let selectedDate = viewModel.selectedDate {
            #expect(calendar.isDate(selectedDate, inSameDayAs: today))
        }
        #expect(calendar.isDate(viewModel.currentDate, inSameDayAs: today))

        #expect(
            calendar.isDate(
                viewModel.dateRange.start,
                equalTo: today.startOfMonth,
                toGranularity: .day
            )
        )
        #expect(
            calendar.isDate(viewModel.dateRange.end, equalTo: today.endOfMonth, toGranularity: .day)
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
}
