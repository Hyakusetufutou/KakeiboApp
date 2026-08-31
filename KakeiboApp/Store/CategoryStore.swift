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

    func reload() async
    func find(id: UUID) -> CategoryModel?
    func add(_ category: CategoryModel) async throws
    func update(_ category: CategoryModel) async throws
    func delete(_ category: CategoryModel) async throws

    func reorder(
        for type: TransactionType,
        from source: IndexSet,
        to destination: Int
    ) async throws
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
                    await reload()
                } catch {
                    errorSubject.send(error)
                }
            }
        }
    }

    // MARK: - Actions
    func reload() async {
        do {
            categoriesInternal = try await repository.fetchAll()
        } catch {
            errorSubject.send(error)
        }
    }

    func find(id: UUID) -> CategoryModel? {
        categoriesInternal.first { $0.id == id }
    }

    func add(_ category: CategoryModel) async throws {
        try await mutateAndReload {
            let categories = self.categoriesInternal.filter { $0.type == category.type }
            let sortOrder = Int32(categories.count)
            let newCategory = try CategoryModel(
                id: category.id,
                name: category.name,
                color: category.color,
                type: category.type,
                isDefault: category.isDefault,
                sortOrder: sortOrder
            )
            try await repository.add(newCategory)
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
            let categories = currentCategories(for: category.type)
            try await normalizeSortOrder(categories: categories)
        }
    }

    func reorder(
        for type: TransactionType,
        from source: IndexSet,
        to destination: Int
    ) async throws {
        try await mutateAndReload {
            var categories = currentCategories(for: type)

            print("変更前")
            print(categories.map { "\($0.name): \($0.sortOrder)" })

            categories.move(
                fromOffsets: source,
                toOffset: destination
            )

            print("move後")
            print(categories.map { "\($0.name): \($0.sortOrder)" })

            for (index, category) in categories.enumerated() {
                let updated = try CategoryModel(
                    id: category.id,
                    name: category.name,
                    color: category.color,
                    type: category.type,
                    isDefault: category.isDefault,
                    sortOrder: Int32(index)
                )

                try await repository.update(updated)
            }
        }
    }

    // MARK: - Private

    private func mutateAndReload(_ operation: () async throws -> Void) async throws {
        try await operation()
        await reload()
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

    private func normalizeSortOrder(
        categories: [CategoryModel]
    ) async throws {
        for (index, category) in categories.enumerated() {
            let updated = try CategoryModel(
                id: category.id,
                name: category.name,
                color: category.color,
                type: category.type,
                isDefault: category.isDefault,
                sortOrder: Int32(index)
            )

            try await repository.update(updated)
        }
    }

    private func currentCategories(for type: TransactionType) -> [CategoryModel] {
        self.categoriesInternal.filter { $0.type == type }
    }
}
