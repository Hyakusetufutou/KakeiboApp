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
    var errorPublisher: AnyPublisher<Error, Never> { get }

    func load(from start: Date, to end: Date) async throws
    func add(_ transaction: TransactionModel) async throws
    func update(_ transaction: TransactionModel) async throws
    func delete(_ transaction: TransactionModel) async throws
    func search(text: String?) async throws -> [TransactionModel]
}

@MainActor
final class TransactionStore: TransactionStoreProtocol {
    // MARK: - State
    @Published private var transactionsInternal: [TransactionModel] = []

    var transactions: AnyPublisher<[TransactionModel], Never> {
        $transactionsInternal.eraseToAnyPublisher()
    }

    private(set) var loadedRange: DateRange?

    private let errorSubject = PassthroughSubject<Error, Never>()

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: TransactionRepositoryProtocol

    // MARK: - Init
    init(
        repository: TransactionRepositoryProtocol,
    ) {
        self.repository = repository
    }

    // MARK: - Actions
    func load(from start: Date, to end: Date) async throws {
        let range = updateLoadedRange(from: start, to: end)
        loadedRange = range

        transactionsInternal = try await repository.fetch(
            from: range.startDate,
            to: range.endDate
        )
    }

    func add(_ transaction: TransactionModel) async throws {
        try await repository.add(transaction)
    }

    func update(_ transaction: TransactionModel) async throws {
        try await repository.update(transaction)
    }

    func delete(_ transaction: TransactionModel) async throws {
        try await repository.delete(transaction)
    }

    func search(text: String?) async throws -> [TransactionModel] {
        guard let normalizedText = StoreSupport.normalizedSearchText(text) else {
            return []
        }
        return try await repository.search(text: normalizedText)
    }

    // MARK: - Private

    private func load() async {
        guard let range = loadedRange else { return }

        do {
            transactionsInternal = try await repository.fetch(
                from: range.startDate,
                to: range.endDate
            )
        } catch {
            errorSubject.send(error)
        }
    }

    private func updateLoadedRange(from start: Date, to end: Date) -> DateRange {
        guard let range = loadedRange else { return DateRange(start: start, end: end) }

        var startDate = range.start
        var endDate = range.end

        if !range.contains(start) {
            startDate = start
        }

        if !range.contains(end) {
            endDate = end
        }

        return DateRange(start: startDate, end: endDate)
    }
}
