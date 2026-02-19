//
//  TransactionStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

//
//  TransactionStore.swift
//  KakeiboApp
//

import Foundation
import Combine

@MainActor
protocol TransactionStoreProtocol {
    var transactions: AnyPublisher<[TransactionModel], Never> { get }

    func add(_ transaction: TransactionModel) async throws
    func update(_ transaction: TransactionModel) async throws
    func delete(_ transaction: TransactionModel) async throws
    func search(text: String?) async -> [TransactionModel]
    func loadMore() async
    func reload() async
}

@MainActor
final class TransactionStore: TransactionStoreProtocol {
    // MARK: - State
    @Published private var _transactions: [TransactionModel] = []

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $_transactions.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol
    private let initialLimit = 100
    private let loadMoreLimit = 50
    private var hasMoreData = true
    private var isLoadingMore = false  // loadMoreの多重実行防止用（内部のみ）

    // MARK: - Init
    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
        Task { await reload() }
    }

    // MARK: - Actions
    func add(_ transaction: TransactionModel) async throws {
        try await repository.add(transaction)
        await reload()
    }

    func update(_ transaction: TransactionModel) async throws {
        try await repository.update(transaction)
        await reload()
    }

    func delete(_ transaction: TransactionModel) async throws {
        try await repository.delete(transaction)
        await reload()
    }

    func search(text: String?) async -> [TransactionModel] {
        do {
            return try await repository.search(text: text)
        } catch {
            // エラー時は空配列を返す
            return []
        }
    }

    func loadMore() async {
        guard hasMoreData, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let offset = _transactions.count
            let newItems = try await repository.fetch(
                from: nil,
                to: nil,
                limit: loadMoreLimit,
                offset: offset
            )

            if newItems.isEmpty {
                hasMoreData = false
                return
            }

            let existingIds = Set(_transactions.map { $0.id })
            let uniqueItems = newItems.filter { !existingIds.contains($0.id) }
            _transactions.append(contentsOf: uniqueItems)
        } catch {
            // エラー時は何もしない
        }
    }

    func reload() async {
        hasMoreData = true

        do {
            let items = try await repository.fetch(
                from: nil,
                to: nil,
                limit: initialLimit,
                offset: 0
            )
            _transactions = items
            hasMoreData = items.count == initialLimit
        } catch {
            // エラー時は現在のデータを保持
        }
    }
}
