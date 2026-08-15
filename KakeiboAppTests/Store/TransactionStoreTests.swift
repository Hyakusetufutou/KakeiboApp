//
//  TransactionStoreTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/11
//
//

import Testing
import Combine
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("TransactionStore のテスト")
struct TransactionStoreTests {

    private func makeSUT() async throws -> (TransactionStore, CategoryModel) {
        let container = PersistenceController(inMemory: true).container
        let categoryRepository = CategoryRepository(container: container)
        let transactionRepository = TransactionRepository(container: container)

        let dummyCategory = CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await categoryRepository.add(dummyCategory)

        let store = TransactionStore(repository: transactionRepository)
        return (store, dummyCategory)
    }

    @Test("load 実行時に loadedRange が適切に更新され、範囲内のトランザクションが読み込まれること")
    func loadTransactionsWithinRange() async throws {
        // Given
        let (store, category) = try await makeSUT()
        let now = Date()
        let calendar = Calendar.current

        let start = calendar.date(byAdding: .day, value: -1, to: now)!
        let end = calendar.date(byAdding: .day, value: 5, to: now)!

        let transaction = TransactionModel(
            id: UUID(),
            title: "スーパー",
            memo: "買い物",
            amount: 2000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )

        // 先にデータを追加（loadedRange が nil のため mutateAndReload 時のリロードはスキップされる）
        try await store.add(transaction)

        // When
        try await store.load(from: start, to: end)

        // Then
        #expect(store.loadedRange != nil)

        // Combine パブリッシャー等の内部状態更新を検証するヘルパーチェック
        var loadedList: [TransactionModel] = []
        let cancellable = store.transactions.sink { loadedList = $0 }
        #expect(loadedList.count == 1)
        #expect(loadedList.first?.id == transaction.id)
        cancellable.cancel()
    }

    @Test("空文字や空白のみの検索クエリを実行した場合、空配列が返されること")
    func searchWithEmptyOrWhitespaceReturnsEmpty() async throws {
        // Given
        let (store, _) = try await makeSUT()

        // When
        let nilResult = try await store.search(text: nil)
        let emptyResult = try await store.search(text: "   ")

        // Then
        #expect(nilResult.isEmpty)
        #expect(emptyResult.isEmpty)
    }

    @Test("正規化されたキーワードで検索が正常に動作すること")
    func searchWithNormalizedText() async throws {
        // Given
        let (store, category) = try await makeSUT()
        let now = Date()

        let t1 = TransactionModel(
            id: UUID(),
            title: "カフェラテ",
            memo: "スタバ",
            amount: 500,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )
        try await store.add(t1)

        // When (前後に空白があるキーワードを渡す -> StoreSupport.normalizedSearchText でトリミングされる)
        let results = try await store.search(text: "  スタバ  ")

        // Then
        #expect(results.count == 1)
        #expect(results.first?.id == t1.id)
    }

    @Test("削除操作後に loadedRange 内のリストが自動更新されること")
    func deleteTransactionAndAutoReload() async throws {
        // Given
        let (store, category) = try await makeSUT()
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -1, to: now)!
        let end = calendar.date(byAdding: .day, value: 1, to: now)!

        // Range を設定してロード
        try await store.load(from: start, to: end)

        let transaction = TransactionModel(
            id: UUID(),
            title: "本",
            memo: "技術書",
            amount: 3000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )

        // 追加（mutateAndReload により内部で load() が発生する）
        try await store.add(transaction)

        // When
        try await store.delete(transaction)

        // Then
        var loadedList: [TransactionModel] = []
        let cancellable = store.transactions.sink { loadedList = $0 }
        #expect(loadedList.isEmpty)
        cancellable.cancel()
    }

    @Test("更新操作後に loadedRange 内のリストが自動更新されること")
    func updateTransactionAndAutoReload() async throws {
        // Given
        let (store, category) = try await makeSUT()
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -1, to: now)!
        let end = calendar.date(byAdding: .day, value: 1, to: now)!

        // Range を設定してロード
        try await store.load(from: start, to: end)

        let transaction = TransactionModel(
            id: UUID(),
            title: "本",
            memo: "技術書",
            amount: 3000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: category.id
        )

        // 追加（mutateAndReload により内部で load() が発生する）
        try await store.add(transaction)

        // When
        let updateDate = Date()
        let updateTransaction = TransactionModel(
            id: transaction.id,
            title: "棋書",
            memo: "将棋の本",
            amount: 2000,
            date: Calendar.current.date(byAdding: .init(day: -1), to: now) ?? now,
            createdAt: transaction.createdAt,
            updatedAt: updateDate,
            type: .expense,
            categoryId: transaction.categoryId
        )
        try await store.update(updateTransaction)

        // Then
        var loadedList: [TransactionModel] = []
        let cancellable = store.transactions.sink { loadedList = $0 }
        let fetchedTransaction = loadedList[0]
        #expect(fetchedTransaction.id == updateTransaction.id)
        #expect(fetchedTransaction.title == updateTransaction.title)
        #expect(fetchedTransaction.memo == updateTransaction.memo)
        #expect(fetchedTransaction.amount == updateTransaction.amount)
        #expect(fetchedTransaction.date == updateTransaction.date)
        #expect(fetchedTransaction.createdAt == updateTransaction.createdAt)
        #expect(fetchedTransaction.updatedAt == updateTransaction.updatedAt)
        #expect(fetchedTransaction.type == updateTransaction.type)
        #expect(fetchedTransaction.categoryId == updateTransaction.categoryId)
        cancellable.cancel()
    }

    @Test("読み込み期間の更新確認")
    func updateloadedRangeCheck() async throws {
        let (store, category) = try await makeSUT()
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -1, to: now)!
        let start2 = calendar.date(byAdding: .day, value: -2, to: now)!
        let end = calendar.date(byAdding: .day, value: 1, to: now)!
        let end2 = calendar.date(byAdding: .day, value: 2, to: now)!

        // Range を設定してロード
        try await store.load(from: start, to: end)

        // 再ロード
        try await store.load(from: start, to: end)
        #expect(store.loadedRange?.start == start)
        #expect(store.loadedRange?.end == end)

        try await store.load(from: start2, to: end)
        #expect(store.loadedRange?.start == start2)
        #expect(store.loadedRange?.end == end)

        try await store.load(from: start, to: end2)
        #expect(store.loadedRange?.start == start2)
        #expect(store.loadedRange?.end == end2)
    }
}
