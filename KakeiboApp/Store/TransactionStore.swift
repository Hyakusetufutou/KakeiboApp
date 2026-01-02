//
//  TransactionStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

import Foundation
import Combine

protocol TransactionStoreProtocol {
    var transactions: AnyPublisher<[TransactionModel], Never> { get }
    var errorMessage: AnyPublisher<String, Never> { get }
    func add(_ transaction: TransactionModel)
    func update(_ transaction: TransactionModel)
    func delete(_ transaction: TransactionModel)
    func search(text: String?) -> [TransactionModel]
}

class TransactionStore: TransactionStoreProtocol {
    @Published private var _transactions: [TransactionModel] = []
    @Published private var _errorMessage: String = ""

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $_transactions.eraseToAnyPublisher()
    }

    var errorMessage: AnyPublisher<String, Never> {
        $_errorMessage.eraseToAnyPublisher()
    }

    private let categoryRepository: CategoryRepositoryProtocol
    private let transactionRepository: TransactionRepository

    init(
        categoryRepository: CategoryRepositoryProtocol,
        transactionRepository: TransactionRepository
    ) {
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        load()
    }

    func add(_ transaction: TransactionModel) {
        switch transactionRepository.add(transaction) {
        case .success(()):
            load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func update(_ transaction: TransactionModel) {
        switch transactionRepository.update(transaction) {
        case .success(()):
            load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func delete(_ transaction: TransactionModel) {
        switch transactionRepository.delete(transaction) {
        case .success(()):
            load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func search(text: String?) -> [TransactionModel] {
        switch transactionRepository.search(text: text) {
        case .success(let transactions):
            return transactions
        case .failure(let error):
            return []
        }
    }

    private func load() {
        // TODO: 全数取得を行うが、期間を限定し都度追加で取得する形にできればした方がいい
        switch transactionRepository.fetch(from: nil, to: nil) {
        case .success(let transactions):
            self._transactions = transactions
            _errorMessage = ""
        case .failure(let error):
            self._transactions = []
            _errorMessage = error.description
        }
    }
}
