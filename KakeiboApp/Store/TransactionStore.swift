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
    var errorMessage: AnyPublisher<String?, Never> { get }
    var isLoading: AnyPublisher<Bool, Never> { get }

    func add(_ transaction: TransactionModel) async
    func update(_ transaction: TransactionModel) async
    func delete(_ transaction: TransactionModel) async
    func search(text: String?) async -> [TransactionModel]
    func loadMore() async
    func reload() async
}

@MainActor
final class TransactionStore: TransactionStoreProtocol {

    // MARK: - State
    @Published private var _transactions: [TransactionModel] = []
    @Published private var _errorMessage: String?
    @Published private var _isLoading = false

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $_transactions.eraseToAnyPublisher()
    }

    var errorMessage: AnyPublisher<String?, Never> {
        $_errorMessage.eraseToAnyPublisher()
    }

    var isLoading: AnyPublisher<Bool, Never> {
        $_isLoading.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol
    private let initialLimit = 100
    private let loadMoreLimit = 50
    private var hasMoreData = true

    // MARK: - Init
    init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
        Task { await reload() }
    }

    // MARK: - Actions
    func add(_ transaction: TransactionModel) async {
        _isLoading = true
        defer { _isLoading = false }

        do {
            try await repository.add(transaction)
            await reloadInternal()
        } catch {
            handleError(error)
        }
    }

    func update(_ transaction: TransactionModel) async {
        _isLoading = true
        defer { _isLoading = false }

        do {
            try await repository.update(transaction)
            await reloadInternal()
        } catch {
            handleError(error)
        }
    }

    func delete(_ transaction: TransactionModel) async {
        _isLoading = true
        defer { _isLoading = false }

        do {
            try await repository.delete(transaction)
            await reloadInternal()
        } catch {
            handleError(error)
        }
    }

    func search(text: String?) async -> [TransactionModel] {
        _isLoading = true
        defer { _isLoading = false }

        do {
            let result = try await repository.search(text: text)
            _errorMessage = nil
            return result
        } catch {
            handleError(error)
            return []
        }
    }

    func loadMore() async {
        guard hasMoreData, !_isLoading else { return }

        _isLoading = true
        defer { _isLoading = false }

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
            handleError(error)
        }
    }

    func reload() async {
        _isLoading = true
        defer { _isLoading = false }

        hasMoreData = true
        await reloadInternal()
    }

    // MARK: - Private
    private func reloadInternal() async {
        do {
            let items = try await repository.fetch(
                from: nil,
                to: nil,
                limit: initialLimit,
                offset: 0
            )
            _transactions = items
            _errorMessage = nil
            hasMoreData = items.count == initialLimit
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        _errorMessage =
            (error as? CustomError)?.description
            ?? error.localizedDescription
    }
}
