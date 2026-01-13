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

    private let categoryRepository: CategoryRepositoryProtocol

    init(categoryRepository: CategoryRepositoryProtocol) {
        self.categoryRepository = categoryRepository
        Task {
            await load()
        }
    }

    func add(_ category: CategoryModel) async {
        _isLoading = true
        let result = await categoryRepository.add(category)
        _isLoading = false

        switch result {
        case .success:
            await load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func update(_ category: CategoryModel) async {
        _isLoading = true
        let result = await categoryRepository.update(category)
        _isLoading = false

        switch result {
        case .success:
            await load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func delete(_ category: CategoryModel) async {
        _isLoading = true
        let result = await categoryRepository.delete(category)
        _isLoading = false

        switch result {
        case .success:
            await load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func find(id: UUID) -> CategoryModel? {
        _categories.first { $0.id == id }
    }

    func reload() async {
        await load()
    }

    private func load() async {
        _isLoading = true
        let result = await categoryRepository.fetchAll()
        _isLoading = false

        switch result {
        case .success(let categories):
            _categories = categories
            _errorMessage = nil
        case .failure(let error):
            _categories = []
            _errorMessage = error.description
        }
    }
}
