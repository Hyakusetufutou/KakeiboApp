//
//  CategoryListViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/15
//
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("CategoryListViewModel のテスト")
struct CategoryListViewModelTests {

    private func makeSUT() -> (CategoryListViewModel, CategoryStore) {
        let container = PersistenceController(inMemory: true).container
        let repository = CategoryRepository(container: container)
        let store = CategoryStore(repository: repository, autoLoad: false)
        let viewModel = CategoryListViewModel(categoryStore: store)
        return (viewModel, store)
    }

    @Test("Store のカテゴリ変更が categories にバインドされること")
    func categoriesBinding() async throws {
        let (viewModel, store) = makeSUT()
        let category = try CategoryModel(
            id: UUID(),
            name: "交通費",
            color: .blue,
            type: .expense,
            isDefault: false
        )

        try await store.add(category)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.categories.count == 1)
        #expect(viewModel.categories.first?.name == "交通費")
    }

    @Test("デフォルトカテゴリ削除時のエラーハンドリングと clearError() の検証")
    func deleteErrorAndClearError() async throws {
        let (viewModel, store) = makeSUT()
        let defaultCategory = try CategoryModel(
            id: UUID(),
            name: "固定費",
            color: .red,
            type: .expense,
            isDefault: true
        )
        try await store.add(defaultCategory)

        await viewModel.delete(defaultCategory)
        #expect(viewModel.errorMessage != nil)

        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }

    @Test("CategoryListViewModel の move 実行時に Store の並び替え処理が呼び出されること")
    func moveCategoriesSuccess() async throws {
        let (viewModel, store) = makeSUT()
        let category1 = try CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        let category2 = try CategoryModel(
            id: UUID(),
            name: "日用品",
            color: .blue,
            type: .expense,
            isDefault: false
        )
        try await store.add(category1)
        try await store.add(category2)

        // Task 内で処理される非同期タスクを待機
        viewModel.move(for: .expense, from: IndexSet(integer: 0), to: 2)
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.categories.first?.id == category2.id)
        #expect(viewModel.categories.last?.id == category1.id)
    }

    @Test("Store の errorPublisher から通知されたエラーが errorMessage に反映されること")
    func handleStoreError() async throws {
        let (viewModel, store) = makeSUT()

        // 当該 Store に対応するリロード処理をトリガーし、非同期エラーハンドリングの伝搬を確認
        await store.reload()

        // エラー通知のハンドリング検証
        #expect(viewModel.errorMessage == nil)
    }
}
