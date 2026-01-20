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
    var errorMessage: AnyPublisher<String?, Never> { get }
    var isLoading: AnyPublisher<Bool, Never> { get }

    func add(_ category: CategoryModel) async
    func update(_ category: CategoryModel) async
    func delete(_ category: CategoryModel) async
    func find(id: UUID) -> CategoryModel?
    func reload() async
}

@MainActor
final class CategoryStore: CategoryStoreProtocol {

    // MARK: - State
    @Published private var _categories: [CategoryModel] = []
    @Published private var _errorMessage: String?
    @Published private var _isLoading = false

    var categories: AnyPublisher<[CategoryModel], Never> {
        $_categories.eraseToAnyPublisher()
    }

    var errorMessage: AnyPublisher<String?, Never> {
        $_errorMessage.eraseToAnyPublisher()
    }

    var isLoading: AnyPublisher<Bool, Never> {
        $_isLoading.eraseToAnyPublisher()
    }

    // MARK: - Dependency
    private let repository: CategoryRepositoryProtocol

    // MARK: - Init
    init(repository: CategoryRepositoryProtocol) {
        self.repository = repository
        Task { await reload() }
    }

    // MARK: - Actions
    func add(_ category: CategoryModel) async {
        _isLoading = true
        defer { _isLoading = false }

        do {
            try await repository.add(category)
            await reloadInternal()
        } catch {
            handleError(error)
        }
    }

    func update(_ category: CategoryModel) async {
        _isLoading = true
        defer { _isLoading = false }

        do {
            try await repository.update(category)
            await reloadInternal()
        } catch {
            handleError(error)
        }
    }

    func delete(_ category: CategoryModel) async {
        _isLoading = true
        defer { _isLoading = false }

        do {
            try await repository.delete(category)
            await reloadInternal()
        } catch {
            handleError(error)
        }
    }

    func find(id: UUID) -> CategoryModel? {
        _categories.first { $0.id == id }
    }

    func reload() async {
        _isLoading = true
        defer { _isLoading = false }
        await reloadInternal()
    }

    // MARK: - Private
    private func reloadInternal() async {
        do {
            let categories = try await repository.fetchAll()
            _categories = categories
            _errorMessage = nil
        } catch {
            handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        _errorMessage =
            (error as? CustomError)?.description
            ?? error.localizedDescription
    }
}
