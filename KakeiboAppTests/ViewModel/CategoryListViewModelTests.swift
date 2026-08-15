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
        let category = CategoryModel(
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
        let defaultCategory = CategoryModel(
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
}
