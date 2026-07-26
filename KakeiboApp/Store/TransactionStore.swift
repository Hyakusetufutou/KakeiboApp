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
    private let initialLimit = StorePagination.initialLimit
    private let loadMoreLimit = StorePagination.loadMoreLimit
    private var isLoadingMore = false
    private var isReloading = false
    private var reloadGeneration = 0

    // MARK: - Init
    init(
        repository: TransactionRepositoryProtocol,
        autoLoad: Bool = true
    ) {
        self.repository = repository
        if autoLoad {
            Task { await reload() }
        }
    }

    // MARK: - Actions
    func add(_ transaction: TransactionModel) async {
        await mutateAndReload {
            try await repository.add(transaction)
        }
    }

    func update(_ transaction: TransactionModel) async {
        await mutateAndReload {
            try await repository.update(transaction)
        }
    }

    func delete(_ transaction: TransactionModel) async {
        await mutateAndReload {
            try await repository.delete(transaction)
        }
    }

    func search(text: String?) async throws -> [TransactionModel] {
        guard StoreSupport.normalizedSearchText(text) != nil else {
            return []
        }
        return try await repository.search(text: text)
    }

    func loadMore() async {
        guard hasMoreDataInternal, !isLoadingMore, !isReloading else { return }

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

            let existingIds = Set(transactionsInternal.map(\.id))
            let uniqueItems = newItems.filter { !existingIds.contains($0.id) }
            transactionsInternal.append(contentsOf: uniqueItems)

            if newItems.count < loadMoreLimit {
                hasMoreDataInternal = false
            }
        } catch {
            errorSubject.send(error)
        }
    }

    func reload() async {
        reloadGeneration += 1
        let generation = reloadGeneration

        isReloading = true
        defer { isReloading = false }

        do {
            let items = try await repository.fetch(
                from: nil,
                to: nil,
                limit: initialLimit,
                offset: 0
            )

            guard generation == reloadGeneration else { return }

            transactionsInternal = items
            hasMoreDataInternal = items.count == initialLimit
        } catch {
            guard generation == reloadGeneration else { return }
            errorSubject.send(error)
        }
    }

    // MARK: - Private

    private func mutateAndReload(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }
}
