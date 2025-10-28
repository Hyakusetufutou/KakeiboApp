//
//  GraphViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/28
//
//

import Foundation

class GraphViewModel: ObservableObject {
    @Published var filteredTransactions: [TransactionModel] = []
    @Published var categorySummaries: [CategorySummary] = []

    @Published var startDate: Date = .now.startOfMonth
    @Published var endDate: Date = .now.endOfMonth
    @Published var selectedType: TransactionType = .expense

    let transactionViewModel: TransactionViewModel
    let categoryViewModel: CategoryViewModel

    init(transactionViewModel: TransactionViewModel, categoryViewModel: CategoryViewModel) {
        self.transactionViewModel = transactionViewModel
        self.categoryViewModel = categoryViewModel
        bindTransactions()
    }

    private func bindTransactions() {
        transactionViewModel.$transactions
            .combineLatest($startDate, $endDate, $selectedType)
            .map { transactions, startDate, endDate, selectedType in
                transactions.filter { transaction in
                    startDate <= transaction.date && transaction.date <= endDate
                        && selectedType == transaction.type

                }
            }
            .handleEvents(receiveOutput: { [weak self] filtered in
                self?.updateCategorySummaries(from: filtered)
            })
            .assign(to: &$filteredTransactions)
    }

    private func updateCategorySummaries(from transactions: [TransactionModel]) {
        let categories = categoryViewModel.categories
        let summaries: [CategorySummary] = categories.compactMap { category in
            let relatedTransactions = transactions.filter {
                $0.categoryId == category.id
            }
            guard !relatedTransactions.isEmpty else { return nil }
            let totalAmount = relatedTransactions.reduce(0) { $0 + $1.amount }

            return CategorySummary(
                categoryID: category.id,
                categoryName: category.name,
                type: category.type,
                totalAmount: totalAmount,
                color: category.color,
                transactions: relatedTransactions
            )
        }

        DispatchQueue.main.async {
            self.categorySummaries = summaries
        }
    }
}
