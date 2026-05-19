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
    var errorPublisher: AnyPublisher<Error, Never> { get }

    func find(id: UUID) -> CategoryModel?
    func add(_ category: CategoryModel) async
    func update(_ category: CategoryModel) async
    func delete(_ category: CategoryModel) async
}

@MainActor
final class CategoryStore: CategoryStoreProtocol {
    // MARK: - State
    @Published private var categoriesInternal: [CategoryModel] = []
    @AppStorage("defaultCategoriesSeeded") private var isSeeded = false

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

    func add(_ category: CategoryModel) async {
        do {
            try await repository.add(category)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    func update(_ category: CategoryModel) async {
        do {
            try await repository.update(category)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    func delete(_ category: CategoryModel) async {
        do {
            guard !category.isDefault else { throw CustomError.cannotDeletedefaultCategory }
            try await repository.delete(category)
            await reload()
        } catch {
            errorSubject.send(error)
        }
    }

    // MARK: - Private
    private func seedDefaultsIfNeeded() async {
        guard !isSeeded else { return }

        do {
            for category in CategoryModel.defaults {
                try await repository.add(category)
            }
            isSeeded = true
        } catch {
            errorSubject.send(error)
        }
    }

    private func reload() async {
        do {
            categoriesInternal = try await repository.fetchAll()
        } catch {
            errorSubject.send(error)
        }
    }
}
