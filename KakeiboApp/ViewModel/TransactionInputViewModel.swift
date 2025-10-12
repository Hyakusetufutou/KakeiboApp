//
//  TransactionInputViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/09
//
//

import Foundation

class TransactionInputViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var memo: String = ""
    @Published var amount: String = ""
    @Published var date: Date = Date()
    @Published var type: TransactionType = .expense
    @Published var selectedCategory: CategoryModel? = nil

    private let transactionViewModel: TransactionViewModel

    init(transactionViewModel: TransactionViewModel) {
        self.transactionViewModel = transactionViewModel
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
            categoryId: selectedCategory?.id ?? UUID()
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
        selectedCategory = nil
    }

    func restore(from transaction: TransactionModel) {
        title = transaction.title
        memo = transaction.memo
        amount = String(transaction.amount)
        date = transaction.date
        type = transaction.type
    }

    private func isValid() -> Bool {
        guard !title.isEmpty, Double(amount) != nil, selectedCategory != nil else {
            return false
        }
        return true
    }
}
