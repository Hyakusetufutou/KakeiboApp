//
//  TransactionStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

import Foundation
import Combine

@MainActor
protocol TransactionStoreProtocol {
    var transactions: AnyPublisher<[TransactionModel], Never> { get }
    var hasMoreData: AnyPublisher<Bool, Never> { get }
    var lastError: AnyPublisher<Error?, Never> { get }

    func add(_ transaction: TransactionModel) async throws
    func update(_ transaction: TransactionModel) async throws
    func delete(_ transaction: TransactionModel) async throws
    func search(text: String?) async throws -> [TransactionModel]
    func loadMore() async
    func reload() async
}

@MainActor
final class TransactionStore: TransactionStoreProtocol {
    // MARK: - State
    @Published private var _transactions: [TransactionModel] = []
    @Published private var _hasMoreData = true
    @Published private var _lastError: Error?

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $_transactions.eraseToAnyPublisher()
    }

    var hasMoreData: AnyPublisher<Bool, Never> {
        $_hasMoreData.eraseToAnyPublisher()
    }

    var lastError: AnyPublisher<Error?, Never> {
        $_lastError.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol
    private let initialLimit = 100
    private let loadMoreLimit = 50
    private var isLoadingMore = false  // loadMoreの多重実行防止用

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

    func search(text: String?) async throws -> [TransactionModel] {
        return try await repository.search(text: text)
    }

    func loadMore() async {
        guard _hasMoreData, !isLoadingMore else { return }

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
                _hasMoreData = false
                return
            }

            // 重複を除いて追加
            let existingIds = Set(_transactions.map { $0.id })
            let uniqueItems = newItems.filter { !existingIds.contains($0.id) }
            _transactions.append(contentsOf: uniqueItems)

            // 取得件数がlimitより少なければ、これ以上データはない
            if newItems.count < loadMoreLimit {
                _hasMoreData = false
            }

            _lastError = nil
        } catch {
            _lastError = error
        }
    }

    func reload() async {
        _hasMoreData = true

        do {
            let items = try await repository.fetch(
                from: nil,
                to: nil,
                limit: nil,
                offset: 0
            )
            _transactions = items

            // 初回読み込みでlimit件未満なら、これ以上データはない
            _hasMoreData = items.count == initialLimit
        } catch {
            // エラー時は現在のデータを保持
            _lastError = error
        }
    }
}
