//
//  MockStores.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/12
//
//

import Foundation
import Combine
@testable import KakeiboApp

// MARK: - MockCategoryStore

@MainActor
final class MockCategoryStore: CategoryStoreProtocol, @unchecked Sendable {
    // 呼び出し記録
    var addCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0

    // 注入するデータ・エラー
    var stubbedCategories: [CategoryModel] = [] {
        didSet { categoriesSubject.send(stubbedCategories) }
    }
    var addError: Error?
    var updateError: Error?
    var deleteError: Error?

    private let categoriesSubject: CurrentValueSubject<[CategoryModel], Never>
    private let lastErrorSubject: CurrentValueSubject<Error?, Never>

    var categories: AnyPublisher<[CategoryModel], Never> {
        categoriesSubject.eraseToAnyPublisher()
    }
    var lastError: AnyPublisher<Error?, Never> {
        lastErrorSubject.eraseToAnyPublisher()
    }

    init(categories: [CategoryModel] = []) {
        self.stubbedCategories = categories
        self.categoriesSubject = CurrentValueSubject(categories)
        self.lastErrorSubject = CurrentValueSubject(nil)
    }

    func find(id: UUID) -> CategoryModel? {
        stubbedCategories.first { $0.id == id }
    }

    func add(_ category: CategoryModel) async throws {
        addCallCount += 1
        if let error = addError { throw error }
        stubbedCategories.append(category)
    }

    func update(_ category: CategoryModel) async throws {
        updateCallCount += 1
        if let error = updateError { throw error }
        if let index = stubbedCategories.firstIndex(where: { $0.id == category.id }) {
            stubbedCategories[index] = category
        }
    }

    func delete(_ category: CategoryModel) async throws {
        deleteCallCount += 1
        if let error = deleteError { throw error }
        stubbedCategories.removeAll { $0.id == category.id }
    }
}

// MARK: - MockTransactionStore

@MainActor
final class MockTransactionStore: TransactionStoreProtocol, @unchecked Sendable {
    // 呼び出し記録
    var addCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var loadMoreCallCount = 0
    var reloadCallCount = 0

    // 注入するデータ・エラー
    var stubbedTransactions: [TransactionModel] = [] {
        didSet { transactionsSubject.send(stubbedTransactions) }
    }
    var stubbedHasMoreData = true {
        didSet { hasMoreDataSubject.send(stubbedHasMoreData) }
    }
    var deleteError: Error?
    var addError: Error?

    var lastError: AnyPublisher<Error?, Never> {
        lastErrorSubject.eraseToAnyPublisher()
    }

    private let transactionsSubject: CurrentValueSubject<[TransactionModel], Never>
    private let hasMoreDataSubject: CurrentValueSubject<Bool, Never>
    private let lastErrorSubject: CurrentValueSubject<Error?, Never>

    var transactions: AnyPublisher<[TransactionModel], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }

    var hasMoreData: AnyPublisher<Bool, Never> {
        hasMoreDataSubject.eraseToAnyPublisher()
    }

    init(transactions: [TransactionModel] = [], hasMoreData: Bool = true) {
        self.stubbedTransactions = transactions
        self.stubbedHasMoreData = hasMoreData
        self.transactionsSubject = CurrentValueSubject(transactions)
        self.hasMoreDataSubject = CurrentValueSubject(hasMoreData)
        self.lastErrorSubject = CurrentValueSubject(nil)
    }

    func add(_ transaction: TransactionModel) async throws {
        addCallCount += 1
        if let error = addError { throw error }
        stubbedTransactions.append(transaction)
    }

    func update(_ transaction: TransactionModel) async throws {
        updateCallCount += 1
        if let index = stubbedTransactions.firstIndex(where: { $0.id == transaction.id }) {
            stubbedTransactions[index] = transaction
        }
    }

    func delete(_ transaction: TransactionModel) async throws {
        deleteCallCount += 1
        if let error = deleteError { throw error }
        stubbedTransactions.removeAll { $0.id == transaction.id }
    }

    func search(text: String?) async -> [TransactionModel] {
        guard let text, !text.isEmpty else { return stubbedTransactions }
        return stubbedTransactions.filter {
            $0.title.contains(text) || ($0.memo).contains(text)
        }
    }

    func loadMore() async {
        loadMoreCallCount += 1
    }

    func reload() async {
        reloadCallCount += 1
    }
}
