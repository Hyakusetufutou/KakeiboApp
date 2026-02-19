//
//  CategoryInputViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/11
//
//

import SwiftUI
import Combine

@MainActor
final class CategoryInputViewModel: ObservableObject {
    @Published var isPresentInputView = false
    @Published var isEdit = false
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var id = UUID()
    @Published var name = ""
    @Published var color: Color = .blue
    @Published var type: TransactionType = .expense

    private let categoryStore: CategoryStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol) {
        self.categoryStore = categoryStore
    }

    // MARK: - Public Methods

    func presentInputView(type: TransactionType, categoryItem: CategoryModel? = nil) {
        self.type = type
        if let category = categoryItem {
            restoreForm(from: category)
            isEdit = true
        } else {
            resetForm()
            isEdit = false
        }
        isPresentInputView = true
    }

    func save() async {
        guard isFormValid else {
            errorMessage = "カテゴリ名を入力してください"
            return
        }

        let category = CategoryModel(
            id: id,
            name: name,
            color: color,
            type: type,
            isDefault: false
        )

        isLoading = true
        defer { isLoading = false }

        do {
            if isEdit {
                try await categoryStore.update(category)
            } else {
                try await categoryStore.add(category)
            }
            // 成功時のみ閉じる
            closeInputView()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
    }

    func cancel() {
        closeInputView()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func resetForm() {
        id = UUID()
        name = ""
        color = .blue
        errorMessage = nil
    }

    private func restoreForm(from category: CategoryModel) {
        id = category.id
        name = category.name
        color = category.color
        type = category.type
        errorMessage = nil
    }

    private func closeInputView() {
        isPresentInputView = false
        errorMessage = nil
        resetForm()
    }
}
