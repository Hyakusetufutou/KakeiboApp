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
    var errorPublisher: AnyPublisher<Error, Never> { get }

    func add(_ transaction: TransactionModel) async
    func update(_ transaction: TransactionModel) async
    func delete(_ transaction: TransactionModel) async
    func search(text: String?) async throws -> [TransactionModel]
    func loadMore() async
    func reload() async
}

@MainActor
final class TransactionStore: TransactionStoreProtocol {
    // MARK: - State
    @Published private var transactionsInternal: [TransactionModel] = []
    @Published private var hasMoreDataInternal = true

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $transactionsInternal.eraseToAnyPublisher()
    }

    var hasMoreData: AnyPublisher<Bool, Never> {
        $hasMoreDataInternal.eraseToAnyPublisher()
    }

    private let errorSubject = PassthroughSubject<Error, Never>()

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
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
    func add(_ transaction: TransactionModel) async {
        do {
            try await repository.add(transaction)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    func update(_ transaction: TransactionModel) async {
        do {
            try await repository.update(transaction)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    func delete(_ transaction: TransactionModel) async {
        do {
            try await repository.delete(transaction)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    func search(text: String?) async throws -> [TransactionModel] {
        return try await repository.search(text: text)
    }

    func loadMore() async {
        guard hasMoreDataInternal, !isLoadingMore else { return }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let offset = transactionsInternal.count
            let newItems = try await repository.fetch(
                from: nil,
                to: nil,
                limit: loadMoreLimit,
                offset: offset
            )

            if newItems.isEmpty {
                hasMoreDataInternal = false
                return
            }

            // 重複を除いて追加
            let existingIds = Set(transactionsInternal.map { $0.id })
            let uniqueItems = newItems.filter { !existingIds.contains($0.id) }
            transactionsInternal.append(contentsOf: uniqueItems)

            // 取得件数がlimitより少なければ、これ以上データはない
            if newItems.count < loadMoreLimit {
                hasMoreDataInternal = false
            }

        } catch {
            errorSubject.send(error)
        }
    }

    func reload() async {
        hasMoreDataInternal = true

        do {
            let items = try await repository.fetch(
                from: nil,
                to: nil,
                limit: nil,
                offset: 0
            )
            transactionsInternal = items

            // 初回読み込みでlimit件未満なら、これ以上データはない
            hasMoreDataInternal = items.count == initialLimit
        } catch {
            errorSubject.send(error)
        }
    }
}
