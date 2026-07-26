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
    func add(_ category: CategoryModel) async
    func update(_ category: CategoryModel) async
    func delete(_ category: CategoryModel) async
    func reload() async
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
                await seedDefaultsIfNeeded()
                await reload()
            }
        }
    }

    // MARK: - Actions
    func find(id: UUID) -> CategoryModel? {
        categoriesInternal.first { $0.id == id }
    }

    func add(_ category: CategoryModel) async {
        await mutateAndReload {
            try await repository.add(category)
        }
    }

    func update(_ category: CategoryModel) async {
        await mutateAndReload {
            try await repository.update(category)
        }
    }

    func delete(_ category: CategoryModel) async {
        do {
            guard !category.isDefault else {
                throw CustomError.cannotDeletedefaultCategory
            }
            try await repository.delete(category)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    func reload() async {
        do {
            categoriesInternal = try await repository.fetchAll()
        } catch {
            errorSubject.send(error)
        }
    }

    // MARK: - Private

    private func seedDefaultsIfNeeded() async {
        do {
            let existing = try await repository.fetchAll()
            let existingIds = Set(existing.map(\.id))
            let missingDefaults = CategoryModel.defaults.filter { !existingIds.contains($0.id) }

            guard !missingDefaults.isEmpty else { return }

            for category in missingDefaults {
                try await repository.add(category)
            }
        } catch {
            errorSubject.send(error)
        }
    }

    private func mutateAndReload(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }
}
