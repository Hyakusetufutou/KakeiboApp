//
//  CategoryListViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/03/04
//
//

import Foundation
import Combine

@MainActor
final class CategoryListViewModel: ObservableObject {
    // MARK: - State
    @Published private(set) var categories: [CategoryModel] = []
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies
    private let categoryStore: CategoryStoreProtocol

    // MARK: - Init
    init(categoryStore: CategoryStoreProtocol) {
        self.categoryStore = categoryStore
        bindCategories()
        bindError()
    }

    // MARK: - Public Methods

    func delete(_ category: CategoryModel) async {
        do {
            try await categoryStore.delete(category)
        } catch {
            errorMessage = ErrorMapper.message(for: error)
        }
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func bindCategories() {
        categoryStore.categories
            .receive(on: DispatchQueue.main)
            .assign(to: &$categories)
    }

    private func bindError() {
        categoryStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
