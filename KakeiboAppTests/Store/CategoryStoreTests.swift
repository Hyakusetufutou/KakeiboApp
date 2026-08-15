//
//  CategoryStoreTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import Testing
import Combine
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("CategoryStore のテスト")
struct CategoryStoreTests {

    private func makeSUT(autoLoad: Bool = false) -> (CategoryStore, CategoryRepository) {
        let container = PersistenceController(inMemory: true).container
        let repository = CategoryRepository(container: container)
        let store = CategoryStore(repository: repository, autoLoad: autoLoad)
        return (store, repository)
    }

    @Test("初期化時に autoLoad が true の場合、デフォルトデータが自動投入されてリロードされること")
    func autoLoadSeedsDefaults() async throws {
        // Given
        let container = PersistenceController(inMemory: true).container
        let repository = CategoryRepository(container: container)

        // autoLoad: true で生成
        let store = CategoryStore(repository: repository, autoLoad: true)

        // Task 内の非同期処理を待機するための十分な微小猶予
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        let categories = try await repository.fetchAll()
        #expect(!categories.isEmpty)
        #expect(store.find(id: categories[0].id) != nil)
    }

    @Test("カテゴリの追加後に Store 内の取得と find が正常に機能すること")
    func addAndFindCategory() async throws {
        // Given
        let (store, _) = makeSUT(autoLoad: false)
        let category = try CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )

        // When
        try await store.add(category)

        // Then
        let found = store.find(id: category.id)
        #expect(found?.id == category.id)
        #expect(found?.name == "食費")
    }

    @Test("デフォルト（isDefault = true）カテゴリを削除しようとすると CustomError がスローされること")
    func deleteDefaultCategoryThrowsError() async throws {
        // Given
        let (store, _) = makeSUT(autoLoad: false)
        let defaultCategory = try CategoryModel(
            id: UUID(),
            name: "固定費",
            color: .blue,
            type: .expense,
            isDefault: true
        )
        try await store.add(defaultCategory)

        // When / Then
        await #expect(throws: CustomError.cannotDeletedefaultCategory) {
            try await store.delete(defaultCategory)
        }
    }

    @Test("カスタムカテゴリの削除が成功すること")
    func deleteCustomCategorySuccess() async throws {
        // Given
        let (store, _) = makeSUT(autoLoad: false)
        let customCategory = try CategoryModel(
            id: UUID(),
            name: "趣味",
            color: .green,
            type: .expense,
            isDefault: false
        )
        try await store.add(customCategory)

        // When
        try await store.delete(customCategory)

        // Then
        #expect(store.find(id: customCategory.id) == nil)
    }

    @Test("カスタムカテゴリの更新が成功すること")
    func updateCustomCategorySuccess() async throws {
        // Given
        let (store, _) = makeSUT(autoLoad: false)
        let customCategory = try CategoryModel(
            id: UUID(),
            name: "趣味",
            color: .green,
            type: .expense,
            isDefault: false
        )
        try await store.add(customCategory)

        // When
        let updateCategory = try CategoryModel(
            id: customCategory.id,
            name: "将棋",
            color: .blue,
            type: .expense,
            isDefault: false
        )
        try await store.update(updateCategory)

        // Then
        let fetchedCategory = store.find(id: customCategory.id)
        #expect(fetchedCategory?.name == updateCategory.name)
        #expect(fetchedCategory?.color == updateCategory.color)
        #expect(fetchedCategory?.type == updateCategory.type)
        #expect(fetchedCategory?.isDefault == updateCategory.isDefault)
    }

}
