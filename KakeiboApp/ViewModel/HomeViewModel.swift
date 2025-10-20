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

    let transactionViewModel: TransactionViewModel
    let categoryViewMdoel: CategoryViewModel
    private var cancellables = Set<AnyCancellable>()

    init(transactionViewModel: TransactionViewModel, categoryViewModel: CategoryViewModel) {
        self.transactionViewModel = transactionViewModel
        self.categoryViewMdoel = categoryViewModel
        bindTransactions()
    }

    private func bindTransactions() {
        transactionViewModel.$transactions
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
