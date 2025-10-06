//
//  TransactionViewModel.swift
//  KakeiboApp
//  
//  Created by Hyakusetufutou on 2025/10/06
//  
//

import Foundation

class TransactionViewModel: ObservableObject {
    
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
    
    func add(_ transaction: TransactionModel) {
        switch transactionRepostory.add(transaction) {
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
}
