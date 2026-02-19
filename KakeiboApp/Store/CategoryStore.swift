//
//  CategoryStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

//
//  CategoryStore.swift
//  KakeiboApp
//

import Foundation
import Combine
import SwiftUI

@MainActor
protocol CategoryStoreProtocol {
    var categories: AnyPublisher<[CategoryModel], Never> { get }

    func find(id: UUID) -> CategoryModel?
    func add(_ category: CategoryModel) async throws
    func update(_ category: CategoryModel) async throws
    func delete(_ category: CategoryModel) async throws
}

@MainActor
final class CategoryStore: CategoryStoreProtocol {
    // MARK: - State
    @Published private var _categories: [CategoryModel] = []

    var categories: AnyPublisher<[CategoryModel], Never> {
        $_categories.eraseToAnyPublisher()
    }

    // MARK: - Dependencies
    private let repository: CategoryRepositoryProtocol

    // MARK: - Init
    init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
        Task { await reload() }
    }

    // MARK: - Actions
    func find(id: UUID) -> CategoryModel? {
        _categories.first { $0.id == id }
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
        try await repository.delete(category)
        await reload()
    }

    // MARK: - Private
    private func reload() async {
        do {
            _categories = try await repository.fetchAll()
        } catch {
            // エラー時は現在のデータを保持
        }
    }
}
