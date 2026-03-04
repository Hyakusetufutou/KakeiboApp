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
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(categoryStore: CategoryStoreProtocol) {
        self.categoryStore = categoryStore
        bindCategories()
    }

    // MARK: - Public Methods

    func delete(_ category: CategoryModel) async {
        do {
            try await categoryStore.delete(category)
        } catch let error as CustomError {
            errorMessage = error.description
        } catch {
            errorMessage = "削除に失敗しました: \(error.localizedDescription)"
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
}
