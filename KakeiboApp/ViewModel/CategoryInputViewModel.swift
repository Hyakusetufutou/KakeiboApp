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
        bindErrorMessage()
    }
    
    func presentInputView(type: TransactionType, categoryItem: CategoryModel? = nil) {
        self.type = type
        if let category = categoryItem {
            restore(category)
            isEdit = true
        } else {
            reset()
            isEdit = false
        }
        isPresentInputView = true
    }
    
    func save() async {
        guard isValid() else {
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
        if isEdit {
            await categoryStore.update(category)
        } else {
            await categoryStore.add(category)
        }
        isLoading = false
        
        reset()
        isPresentInputView = false
    }
    
    func cancel() {
        reset()
        isPresentInputView = false
        errorMessage = nil
    }
    
    private func reset() {
        id = UUID()
        name = ""
        color = .blue
    }
    
    private func restore(_ category: CategoryModel) {
        id = category.id
        name = category.name
        color = category.color
        type = category.type
    }
    
    private func isValid() -> Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func bindErrorMessage() {
        categoryStore.errorMessage
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
