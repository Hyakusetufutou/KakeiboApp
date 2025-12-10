//
//  GraphViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/28
//
//

import Foundation
import Combine

class GraphViewModel: ObservableObject {
    @Published var filteredTransactions: [TransactionModel] = []
    @Published var categorySummaries: [CategorySummary] = []

    @Published var startDate: Date = .now.startOfMonth
    @Published var endDate: Date = .now.endOfMonth
    @Published var selectedType: TransactionType = .expense

    let transactionViewModel: TransactionViewModel
    let categoryViewModel: CategoryViewModel

    private var cancellables = Set<AnyCancellable>()

    init(transactionViewModel: TransactionViewModel, categoryViewModel: CategoryViewModel) {
        self.transactionViewModel = transactionViewModel
        self.categoryViewModel = categoryViewModel
        bindTransactions()
        bindCategorySummaries()
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
            .assign(to: &$filteredTransactions)
    }

    private func bindCategorySummaries() {
        $filteredTransactions
            .combineLatest($selectedType)
            .sink { [weak self] transactions, selectedType in
                guard let self = self else { return }
                self.updateCategorySummaries(from: transactions, type: selectedType)
            }
            .store(in: &cancellables)
    }

    private func updateCategorySummaries(
        from transactions: [TransactionModel],
        type: TransactionType
    ) {
        let categories = categoryViewModel.categories

        let summaries =
            categories
            .filter { $0.type == type }
            .compactMap { category -> CategorySummary? in
                let related = transactions.filter { $0.categoryId == category.id }
                let total = related.map(\.amount)
                    .filter { $0.isFinite && !$0.isNaN }
                    .reduce(0, +)

                guard total > 0 else { return nil }

                return CategorySummary(
                    categoryID: category.id,
                    categoryName: category.name,
                    type: category.type,
                    totalAmount: total,
                    color: category.color,
                    transactions: related
                )
            }

        DispatchQueue.main.async {
            self.categorySummaries = summaries
        }
    }

    func changeMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: startDate)
        else { return }
        startDate = newDate.startOfMonth
        endDate = newDate.endOfMonth
    }
}
