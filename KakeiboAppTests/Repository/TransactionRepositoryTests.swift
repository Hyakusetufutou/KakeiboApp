//
//  TransactionRepositoryTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/15
//
//

import Testing
import CoreData
@testable import KakeiboApp

@Suite("TransactionRepository のテスト")
struct TransactionRepositoryTests {

    // テストに必要なSUT（System Under Test）およびダミーカテゴリを用意するヘルパー
    private func makeSUT() async throws -> (TransactionRepository, CategoryModel) {
        let container = PersistenceController(inMemory: true).container
        let categoryRepository = CategoryRepository(container: container)
        let transactionRepository = TransactionRepository(container: container)

        let dummyCategory = try CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await categoryRepository.add(dummyCategory)

        return (transactionRepository, dummyCategory)
    }

    @Test("指定期間内のトランザクションのみが取得できること")
    func fetchDateRange() async throws {
        // Given
        let (repository, dummyCategory) = try await makeSUT()
        let now = Date()
        let calendar = Calendar.current

        guard let targetDate = calendar.date(byAdding: .day, value: 2, to: now),
            let outOfRangeDate = calendar.date(byAdding: .day, value: 10, to: now),
            let startDate = calendar.date(byAdding: .day, value: -1, to: now),
            let endDate = calendar.date(byAdding: .day, value: 5, to: now)
        else {
            Issue.record("日付の生成に失敗しました")
            return
        }

        let transaction1 = try TransactionModel(
            id: UUID(),
            title: "スーパーで買い物",
            memo: "食材",
            amount: 1000,
            date: targetDate,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )

        let transaction2 = try TransactionModel(
            id: UUID(),
            title: "外食",
            memo: "ディナー",
            amount: 5000,
            date: outOfRangeDate,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )

        try await repository.add(transaction1)
        try await repository.add(transaction2)

        // When
        let results = try await repository.fetch(from: startDate, to: endDate)

        // Then
        #expect(results.count == 1)
        #expect(results.first?.id == transaction1.id)
        #expect(results.first?.title == "スーパーで買い物")
    }

    @Test("タイトルまたはメモの部分一致検索ができること")
    func searchByText() async throws {
        // Given
        let (repository, dummyCategory) = try await makeSUT()
        let now = Date()

        let t1 = try TransactionModel(
            id: UUID(),
            title: "コンビニでお菓子",
            memo: "おやつ",
            amount: 300,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )

        let t2 = try TransactionModel(
            id: UUID(),
            title: "カフェ",
            memo: "コンビニの近く",
            amount: 1500,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )

        let t3 = try TransactionModel(
            id: UUID(),
            title: "書店",
            memo: "技術書",
            amount: 2000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )

        try await repository.add(t1)
        try await repository.add(t2)
        try await repository.add(t3)

        // When
        let results = try await repository.search(text: "コンビニ")

        // Then
        #expect(results.count == 2)
        let ids = results.map { $0.id }
        #expect(ids.contains(t1.id))
        #expect(ids.contains(t2.id))
        #expect(!ids.contains(t3.id))
    }

    @Test("トランザクションの更新が反映されること")
    func updateTransaction() async throws {
        // Given
        let (repository, dummyCategory) = try await makeSUT()
        let now = Date()

        let initialModel = try TransactionModel(
            id: UUID(),
            title: "ランチ",
            memo: "ラーメン",
            amount: 1000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )
        try await repository.add(initialModel)

        // When
        let updatedModel = try TransactionModel(
            id: initialModel.id,
            title: "豪華ランチ",
            memo: "ラーメン（トッピング追加）",
            amount: 1200,
            date: now,
            createdAt: now,
            updatedAt: Date(),
            type: .expense,
            categoryId: dummyCategory.id
        )
        try await repository.update(updatedModel)

        // Then
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let results = try await repository.fetch(from: startDate, to: endDate)

        #expect(results.count == 1)
        #expect(results.first?.amount == 1200)
        #expect(results.first?.title == "豪華ランチ")
    }

    @Test("トランザクションの削除ができること")
    func deleteTransaction() async throws {
        // Given
        let (repository, dummyCategory) = try await makeSUT()
        let now = Date()

        let model = try TransactionModel(
            id: UUID(),
            title: "コーヒー",
            memo: "",
            amount: 500,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )
        try await repository.add(model)

        // When
        try await repository.delete(model)

        // Then
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let endDate = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let results = try await repository.fetch(from: startDate, to: endDate)

        #expect(results.isEmpty)
    }
}
