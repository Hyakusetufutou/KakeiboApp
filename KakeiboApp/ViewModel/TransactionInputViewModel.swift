//
//  TransactionInputViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/09
//
//

import Foundation

class TransactionInputViewModel: ObservableObject {
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
        categoryViewModel.categories.first { $0.id == selectedCategoryId }
    }

    private let transactionViewModel: TransactionViewModel
    private let categoryViewModel: CategoryViewModel

    init(transactionViewModel: TransactionViewModel, categoryViewModel: CategoryViewModel) {
        self.transactionViewModel = transactionViewModel
        self.categoryViewModel = categoryViewModel
    }

    func presentInputView(_ transactionItem: TransactionModel? = nil) {
        if let transaction = transactionItem {
            restore(from: transaction)
        } else {
            reset()
        }
    }

    func save(onSuccess: () -> Void) {
        guard isValid() else { return }

        let newTransaction = TransactionModel(
            title: title,
            memo: memo,
            amount: Double(amount) ?? 0,
            date: date,
            createAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: selectedCategoryId ?? UUID()
        )
        transactionViewModel.add(newTransaction)
        reset()
        onSuccess()
    }

    func reset() {
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
        amount = String(transaction.amount)
        date = transaction.date
        type = transaction.type
        selectedCategoryId = transaction.categoryId
    }

    private func isValid() -> Bool {
        guard !title.isEmpty, Double(amount) != nil, selectedCategoryId != nil else {
            return false
        }
        return true
    }
}
