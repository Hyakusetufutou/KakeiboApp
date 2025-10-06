//
//  TransactionViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/06
//
//

import Foundation

class TransactionViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var memo: String = ""
    @Published var amount: String = ""
    @Published var date: Date = Date()
    @Published var type: TransactionType = .expense
    @Published var categoryId: UUID = UUID()  //@@@

    @Published var errorMessage: String = ""

    private let transactionRepostory: TransactionRepository
    private let categoryRepository: CategoryRepository

    init(transactionRepostory: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepostory = transactionRepostory
        self.categoryRepository = categoryRepository
    }

    func fetch(startDate: Date, endDate: Date) -> [TransactionModel] {
        switch transactionRepostory.fetch(from: startDate, to: endDate) {
        case .success(let transactions):
            return transactions
        case .failure(let error):
            errorMessage = error.description
            return []
        }
    }

    func add() {
        guard isValidTransactionInput() else { return }
        switch transactionRepostory.add(
            TransactionModel(
                title: title,
                memo: memo,
                amount: Double(amount) ?? Double(0),
                date: date,
                createAt: Date(),
                updatedAt: Date(),
                type: type,
                categoryId: categoryId
            )
        ) {
        case .success(()):
            return
        case .failure(let error):
            errorMessage = error.description
        }
    }

    func delete(_ transaction: TransactionModel) {
        switch transactionRepostory.delete(transaction) {
        case .success(()):
            return
        case .failure(let error):
            errorMessage = error.description
        }
    }

    func edit(_ transaction: TransactionModel) {
        switch transactionRepostory.update(transaction) {
        case .success(()):
            return
        case .failure(let error):
            errorMessage = error.description
        }
    }

    func resetInput() {
        title = ""
        memo = ""
        amount = ""
        date = Date()
        type = .expense
        categoryId = UUID()  //@@@
    }
    
    func restoreInput(_ transaction: TransactionModel) {
        title = transaction.title
        memo = transaction.memo
        amount = String(transaction.amount)
        date = transaction.date
        type = transaction.type
        categoryId = transaction.categoryId
    }

    private func isValidTransactionInput() -> Bool {
        guard !title.isEmpty && !amount.isEmpty && Double(amount) != nil else {
            return false
        }
        return true
    }
}
