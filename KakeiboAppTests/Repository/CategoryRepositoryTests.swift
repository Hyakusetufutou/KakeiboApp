//
//  CategoryRepositoryTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/15
//
//

import Testing
import CoreData
@testable import KakeiboApp

@Suite("CategoryRepository のテスト")
struct CategoryRepositoryTests {

    // 各テストで独立したインメモリコンテナとRepositoryを生成
    private func makeSUT() -> (CategoryRepository, NSPersistentContainer) {
        let container = PersistenceController(inMemory: true).container
        let repository = CategoryRepository(container: container)
        return (repository, container)
    }

    @Test("カテゴリの追加と取得が正常に行えること")
    func addAndFetch() async throws {
        // Given
        let (repository, _) = makeSUT()
        let model = CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )

        // When
        try await repository.add(model)
        let fetchedModel = try await repository.fetch(by: model.id)

        // Then
        #expect(fetchedModel.id == model.id)
        #expect(fetchedModel.name == "食費")
        #expect(fetchedModel.color == .red)
        #expect(fetchedModel.type == .expense)
        #expect(fetchedModel.isDefault == false)
    }

    @Test("fetchAll が名前の昇順でソートされて取得できること")
    func fetchAllSortedByName() async throws {
        // Given
        let (repository, _) = makeSUT()
        let categoryA = CategoryModel(
            id: UUID(),
            name: "日用品",
            color: .blue,
            type: .expense,
            isDefault: false
        )
        let categoryB = CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        let categoryC = CategoryModel(
            id: UUID(),
            name: "交通費",
            color: .green,
            type: .expense,
            isDefault: false
        )

        try await repository.add(categoryA)
        try await repository.add(categoryB)
        try await repository.add(categoryC)

        // When
        let categories = try await repository.fetchAll()

        // Then
        #expect(categories.count == 3)
        // 昇順ソート確認: 交通費 -> 日用品 -> 食費
        #expect(categories[0].name == "交通費")
        #expect(categories[1].name == "日用品")
        #expect(categories[2].name == "食費")
    }

    @Test("カテゴリの更新が反映されること")
    func updateCategory() async throws {
        // Given
        let (repository, _) = makeSUT()
        let initialModel = CategoryModel(
            id: UUID(),
            name: "外食",
            color: .orange,
            type: .expense,
            isDefault: false
        )
        try await repository.add(initialModel)

        // When
        let updatedModel = CategoryModel(
            id: initialModel.id,
            name: "外食・カフェ",
            color: .yellow,
            type: .expense,
            isDefault: true
        )
        try await repository.update(updatedModel)

        // Then
        let fetchedModel = try await repository.fetch(by: initialModel.id)
        #expect(fetchedModel.name == "外食・カフェ")
        #expect(fetchedModel.color == .yellow)
        #expect(fetchedModel.isDefault == true)
    }

    @Test("削除したカテゴリの取得でエラーがスローされること")
    func deleteCategory() async throws {
        // Given
        let (repository, _) = makeSUT()
        let model = CategoryModel(
            id: UUID(),
            name: "趣味",
            color: .purple,
            type: .expense,
            isDefault: false
        )
        try await repository.add(model)

        // When
        try await repository.delete(model)

        // Then
        await #expect(throws: Error.self) {
            _ = try await repository.fetch(by: model.id)
        }
    }
}
