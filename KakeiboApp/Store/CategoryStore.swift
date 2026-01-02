//
//  CategoryStore.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/01
//
//

import Foundation
import Combine

protocol CategoryStoreProtocol {
    var categories: AnyPublisher<[CategoryModel], Never> { get }
    var errorMessage: AnyPublisher<String, Never> { get }
    func add(_ category: CategoryModel)
    func update(_ category: CategoryModel)
    func delete(_ category: CategoryModel)
    func find(id: UUID) -> CategoryModel?
}

class CategoryStore: CategoryStoreProtocol {
    @Published private var _categories: [CategoryModel] = []
    @Published private var _errorMessage: String = ""

    var categories: AnyPublisher<[CategoryModel], Never> {
        $_categories.eraseToAnyPublisher()
    }

    var errorMessage: AnyPublisher<String, Never> {
        $_errorMessage.eraseToAnyPublisher()
    }

    private let categoryRepository: CategoryRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    init(categoryRepository: CategoryRepositoryProtocol) {
        self.categoryRepository = categoryRepository
        load()
    }

    func add(_ category: CategoryModel) {
        switch categoryRepository.add(category) {
        case .success(()):
            load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func update(_ category: CategoryModel) {
        switch categoryRepository.update(category) {
        case .success(()):
            load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func delete(_ category: CategoryModel) {
        switch categoryRepository.delete(category) {
        case .success(()):
            load()
        case .failure(let error):
            _errorMessage = error.description
        }
    }

    func find(id: UUID) -> CategoryModel? {
        _categories.first { $0.id == id }
    }

    private func load() {
        switch categoryRepository.fetchAll() {
        case .success(let categories):
            self._categories = categories
            _errorMessage = ""
        case .failure(let error):
            self._categories = []
            _errorMessage = error.description
        }
    }
}
