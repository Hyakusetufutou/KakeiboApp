//
//  TransactionViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/06
//
//

import Foundation

class TransactionViewModel: ObservableObject {
    @Published var transactions: [TransactionModel] = []

    @Published var errorMessage: String = ""

    private let transactionRepostory: TransactionRepository
    private let categoryRepository: CategoryRepository

    init(transactionRepostory: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepostory = transactionRepostory
        self.categoryRepository = categoryRepository
        fetch(startDate: .now.startOfMonth, endDate: .now.endOfMonth)
    }

    func fetch(startDate: Date, endDate: Date) {
        switch transactionRepostory.fetch(from: startDate, to: endDate) {
        case .success(let transactions):
            self.transactions = transactions
        case .failure(let error):
            self.transactions = []
            errorMessage = error.description
        }
    }

    func add(_ transaction: TransactionModel) {
        switch transactionRepostory.add(transaction) {
        case .success(()):
            fetch(startDate: .now.startOfMonth, endDate: .now.endOfMonth)
        case .failure(let error):
            errorMessage = error.description
        }
    }

    func delete(_ transaction: TransactionModel) {
        switch transactionRepostory.delete(transaction) {
        case .success(()):
            fetch(startDate: .now.startOfMonth, endDate: .now.endOfMonth)
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
}
