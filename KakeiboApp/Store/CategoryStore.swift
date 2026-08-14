//
//  CategoryStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

import Foundation
import Combine

@MainActor
protocol CategoryStoreProtocol {
    var categories: AnyPublisher<[CategoryModel], Never> { get }
    var errorPublisher: AnyPublisher<Error, Never> { get }

    func find(id: UUID) -> CategoryModel?
    func add(_ category: CategoryModel) async throws
    func update(_ category: CategoryModel) async throws
    func delete(_ category: CategoryModel) async throws
}

@MainActor
final class CategoryStore: CategoryStoreProtocol {
    // MARK: - State
    @Published private var categoriesInternal: [CategoryModel] = []

    var categories: AnyPublisher<[CategoryModel], Never> {
        $categoriesInternal.eraseToAnyPublisher()
    }

    private let errorSubject = PassthroughSubject<Error, Never>()

    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: CategoryRepositoryProtocol

    // MARK: - Init
    init(
        repository: CategoryRepositoryProtocol,
        autoLoad: Bool = true
    ) {
        self.repository = repository
        if autoLoad {
            Task {
                do {
                    try await seedDefaultsIfNeeded()
                    try await reload()
                } catch {
                    errorSubject.send(error)
                }
            }
        }
    }

    // MARK: - Actions
    func find(id: UUID) -> CategoryModel? {
        categoriesInternal.first { $0.id == id }
    }

    func add(_ category: CategoryModel) async throws {
        try await mutateAndReload {
            try await repository.add(category)
        }
    }

    func update(_ category: CategoryModel) async throws {
        try await mutateAndReload {
            try await repository.update(category)
        }
    }

    func delete(_ category: CategoryModel) async throws {
        try await mutateAndReload {
            guard !category.isDefault else {
                throw CustomError.cannotDeletedefaultCategory
            }
            try await repository.delete(category)
        }
    }

    // MARK: - Private

    private func reload() async throws {
        categoriesInternal = try await repository.fetchAll()
    }

    private func mutateAndReload(_ operation: () async throws -> Void) async throws {
        try await operation()
        try await reload()
    }

    private func seedDefaultsIfNeeded() async throws {
        let existing = try await repository.fetchAll()
        let existingIds = Set(existing.map(\.id))
        let missingDefaults = CategoryModel.defaults.filter { !existingIds.contains($0.id) }

        guard !missingDefaults.isEmpty else { return }

        for category in missingDefaults {
            try await repository.add(category)
        }
    }
}
