//
//  HomeViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/07
//
//

import Foundation
import Combine

class HomeViewModel: ObservableObject {
    @Published var filterdTransactions: [TransactionModel] = []

    @Published var startDate: Date = .now.startOfMonth
    @Published var endDate: Date = .now.endOfMonth
    @Published var selectedType: TransactionType = .expense
    @Published var showFilterView: Bool = false

    let categoryStore: CategoryStoreProtocol
    let transactionStore: TransactionStoreProtocol

    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindTransactions()
    }

    func categoryFind(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func deleteTransaction(_ transaction: TransactionModel) {
        transactionStore.delete(transaction)
    }

    private func bindTransactions() {
        transactionStore.transactions
            .combineLatest($startDate, $endDate, $selectedType)
            .map { transactions, startDate, endDate, selectedType in
                transactions.filter { transaction in
                    startDate <= transaction.date
                        && transaction.date <= endDate
                }
            }
            .assign(to: &$filterdTransactions)
    }
}
