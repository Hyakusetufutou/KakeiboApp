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

    @Published var name: String = ""
    @Published var color: Color = .blue
    @Published var type: TransactionType = .expense

    @Published var errorMessage: String = ""

    private let repository: CategoryRepository

    init(repository: CategoryRepository) {
        self.repository = repository
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

    func add() {
        guard isValidCategoryInput() else { return }
        switch repository.add(
            CategoryModel(name: name, color: color, type: .expense, isDefault: false)
        ) {
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

    func resetInput() {
        name = ""
        color = .blue
        type = .expense
    }

    func resotreInput(_ categoryItem: CategoryModel) {
        name = categoryItem.name
        color = categoryItem.color
        type = categoryItem.type
    }

    private func isValidCategoryInput() -> Bool {
        guard !name.isEmpty else { return false }
        return true
    }
}
