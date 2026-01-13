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
    func loadMore(limit: Int, offset: Int) async
    func reload() async
}

@MainActor
final class TransactionStore: TransactionStoreProtocol {
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

    private let transactionRepository: TransactionRepositoryProtocol
    private let initialLoadLimit = 100

    init(transactionRepository: TransactionRepositoryProtocol) {
        self.transactionRepository = transactionRepository
        Task {
            await load()
        }
    }

    func add(_ transaction: TransactionModel) async {
        _isLoading = true
        let result = await transactionRepository.add(transaction)
        _isLoading = false

        switch result {
        case .success:
            await load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func update(_ transaction: TransactionModel) async {
        _isLoading = true
        let result = await transactionRepository.update(transaction)
        _isLoading = false

        switch result {
        case .success:
            await load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func delete(_ transaction: TransactionModel) async {
        _isLoading = true
        let result = await transactionRepository.delete(transaction)
        _isLoading = false

        switch result {
        case .success:
            await load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func search(text: String?) async -> [TransactionModel] {
        let result = await transactionRepository.search(text: text)
        switch result {
        case .success(let transactions):
            return transactions
        case .failure(let error):
            _errorMessage = error.description
            return []
        }
    }

    func loadMore(limit: Int = 50, offset: Int) async {
        let result = await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: limit,
            offset: offset
        )

        switch result {
        case .success(let newTransactions):
            _transactions.append(contentsOf: newTransactions)
            _errorMessage = nil
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func reload() async {
        await load()
    }

    private func load() async {
        _isLoading = true
        let result = await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: initialLoadLimit,
            offset: 0
        )
        _isLoading = false

        switch result {
        case .success(let transactions):
            _transactions = transactions
            _errorMessage = nil
        case .failure(let error):
            _transactions = []
            _errorMessage = error.description
        }
    }
}
