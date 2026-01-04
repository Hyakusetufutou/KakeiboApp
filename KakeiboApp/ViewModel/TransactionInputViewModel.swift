//
//  TransactionInputViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/09
//
//

import Foundation
import Combine

@MainActor
final class TransactionInputViewModel: ObservableObject {
    @Published var categories: [CategoryModel] = []

    @Published var isPresentInputView: Bool = false
    @Published var isEdit: Bool = false

    @Published var id: UUID = UUID()
    @Published var title: String = ""
    @Published var memo: String = ""
    @Published var amount: String = ""
    @Published var date: Date = Date()
    @Published var type: TransactionType = .expense
    @Published var selectedCategoryId: UUID?

    var selectedCategory: CategoryModel? {
        categories.first { $0.id == selectedCategoryId }
    }

    var availableCategories: [CategoryModel] {
        categories.filter { $0.type == type }
    }

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol

    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindCategories()
    }

    func resetSelectedCategory() {
        selectedCategoryId = nil
    }

    func presentInputView(_ transactionItem: TransactionModel? = nil) {
        if let transaction = transactionItem {
            restore(from: transaction)
            isEdit = true
        } else {
            reset()
            isEdit = false
        }
        isPresentInputView = true
    }

    func save() {
        guard isValid() else { return }

        let transaction = TransactionModel(
            id: id,
            title: title,
            memo: memo,
            amount: Double(amount) ?? 0,
            date: date,
            createAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: selectedCategoryId ?? UUID()
        )

        if isEdit {
            transactionStore.update(transaction)
        } else {
            transactionStore.add(transaction)
        }

        reset()
        cancel()
    }

    func cancel() {
        isPresentInputView = false
    }

    func reset() {
        id = UUID()
        title = ""
        memo = ""
        amount = ""
        date = Date()
        type = .expense
        selectedCategoryId = nil
    }

    func restore(from transaction: TransactionModel) {
        id = transaction.id
        title = transaction.title
        memo = transaction.memo
        amount = String(Int(transaction.amount))
        date = transaction.date
        type = transaction.type
        selectedCategoryId = transaction.categoryId
    }

    func isValid() -> Bool {
        guard !title.isEmpty, Double(amount) != nil, selectedCategoryId != nil else {
            return false
        }
        return true
    }

    private func bindCategories() {
        categoryStore.categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                self?.categories = categories
            }
            .store(in: &cancellables)
    }
}
