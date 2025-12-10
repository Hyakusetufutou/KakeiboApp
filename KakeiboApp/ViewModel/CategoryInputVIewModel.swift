//
//  CategoryInputVIewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/11
//
//

import SwiftUI

class CategoryInputViewModel: ObservableObject {
    @Published var isPresentInputView: Bool = false
    @Published var isEdit: Bool = false

    @Published var id: UUID = UUID()
    @Published var name: String = ""
    @Published var color: Color = .blue
    @Published var type: TransactionType = .expense

    private let categoryViewModel: CategoryViewModel

    init(categoryViewModel: CategoryViewModel) {
        self.categoryViewModel = categoryViewModel
    }

    func presentInputView(_ categoryItem: CategoryModel? = nil) {
        if let category = categoryItem {
            restore(category)
            isEdit = true
        } else {
            reset()
            isEdit = false
        }
        isPresentInputView = true
    }

    func save() {
        guard isValid() else { return }
        let category = CategoryModel(id: id, name: name, color: color, type: type, isDefault: false)

        if isEdit {
            categoryViewModel.edit(category)
        } else {
            categoryViewModel.add(category)
        }
        reset()
        isPresentInputView = false
    }

    func cancel() {
        isPresentInputView = false
    }

    func reset() {
        id = UUID()
        name = ""
        color = .blue
        type = .expense
    }

    func restore(_ category: CategoryModel) {
        id = category.id
        name = category.name
        color = category.color
        type = category.type
    }

    private func isValid() -> Bool {
        guard !name.isEmpty else { return false }
        return true
    }
}
