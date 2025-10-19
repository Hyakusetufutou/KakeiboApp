//
//  CategoryViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/05
//
//

import SwiftUI

class CategoryViewModel: ObservableObject {
    @Published var categories: [CategoryModel] = []
    @Published var errorMessage: String = ""

    private let repository: CategoryRepository

    init(repository: CategoryRepository) {
        self.repository = repository
        fetch()
    }

    func fetch() {
        switch repository.fetchAll() {
        case .success(let categories):
            self.categories = categories
        case .failure(let error):
            self.categories = []
            errorMessage = error.description
        }
    }

    func add(_ category: CategoryModel) {
        switch repository.add(category) {
        case .success(()):
            fetch()
        case .failure(let error):
            errorMessage = error.description
        }
    }

    func delete(_ categoryItem: CategoryModel) {
        switch repository.delete(categoryItem) {
        case .success(()):
            fetch()
        case .failure(let error):
            errorMessage = error.description
        }
    }

    func edit(_ categoryItem: CategoryModel) {
        switch repository.update(categoryItem) {
        case .success(()):
            fetch()
        case .failure(let error):
            errorMessage = error.description
        }
    }
}
