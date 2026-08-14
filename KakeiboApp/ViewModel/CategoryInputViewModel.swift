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
    @Published var color: CategoryColor = .blue
    @Published var type: TransactionType = .expense

    var isDefault = false

    private let categoryStore: CategoryStoreProtocol

    init(categoryStore: CategoryStoreProtocol) {
        self.categoryStore = categoryStore
        bindError()
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

        clearError()

        let category = CategoryModel(
            id: id,
            name: name,
            color: color,
            type: type,
            isDefault: isDefault
        )

        isLoading = true
        defer { isLoading = false }

        // ストア側のエラーを一度クリアしてから実行
        do {
            if isEdit {
                try await categoryStore.update(category)
            } else {
                try await categoryStore.add(category)
            }

            closeInputView()
        } catch {
            errorMessage = ErrorMapper.message(for: error)
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
        isDefault = false
        errorMessage = nil
    }

    private func restoreForm(from category: CategoryModel) {
        id = category.id
        name = category.name
        color = category.color
        type = category.type
        isDefault = category.isDefault
        errorMessage = nil
    }

    private func closeInputView() {
        isPresentInputView = false
        errorMessage = nil
        resetForm()
    }

    private func bindError() {
        categoryStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
