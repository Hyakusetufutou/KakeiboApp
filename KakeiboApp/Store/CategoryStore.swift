//
//  CategoryStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

import Foundation
import Combine
import SwiftUI

@MainActor
protocol CategoryStoreProtocol {
    var categories: AnyPublisher<[CategoryModel], Never> { get }
    var lastError: AnyPublisher<Error?, Never> { get }

    func find(id: UUID) -> CategoryModel?
    func add(_ category: CategoryModel) async throws
    func update(_ category: CategoryModel) async throws
    func delete(_ category: CategoryModel) async throws
}

@MainActor
final class CategoryStore: CategoryStoreProtocol {
    // MARK: - State
    @Published private var categoriesInternal: [CategoryModel] = []
    @Published private var lastErrorInternal: Error?
    @AppStorage("defaultCategoriesSeeded") private var isSeeded = false

    var categories: AnyPublisher<[CategoryModel], Never> {
        $categoriesInternal.eraseToAnyPublisher()
    }
    var lastError: AnyPublisher<Error?, Never> {
        $lastErrorInternal.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: CategoryRepositoryProtocol

    // MARK: - Init
    init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
        Task {
            await seedDefaultsIfNeeded()
            await reload()
        }
    }

    // MARK: - Actions
    func find(id: UUID) -> CategoryModel? {
        categoriesInternal.first { $0.id == id }
    }

    func add(_ category: CategoryModel) async throws {
        try await repository.add(category)
        await reload()
    }

    func update(_ category: CategoryModel) async throws {
        try await repository.update(category)
        await reload()
    }

    func delete(_ category: CategoryModel) async throws {
        guard !category.isDefault else { throw CustomError.cannotDeletedefaultCategory }
        try await repository.delete(category)
        await reload()
    }

    // MARK: - Private
    private func seedDefaultsIfNeeded() async {
        guard !isSeeded else { return }

        do {
            for category in CategoryModel.defaults {
                try await repository.add(category)
                isSeeded = true
            }
        } catch {
            lastErrorInternal = error
        }
    }

    private func reload() async {
        do {
            categoriesInternal = try await repository.fetchAll()
            lastErrorInternal = nil
        } catch {
            lastErrorInternal = error
        }
    }
}
