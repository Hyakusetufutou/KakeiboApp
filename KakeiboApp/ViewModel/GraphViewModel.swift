//
//  GraphViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/28
//
//

import Foundation
import Combine

@MainActor
final class GraphViewModel: ObservableObject {
    @Published private(set) var categorySummaries: [CategorySummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var categories: [CategoryModel] = []
    @Published var startDate: Date = Date().startOfMonth
    @Published var endDate: Date = Date().endOfMonth
    @Published var selectedType: TransactionType = .expense

    var totalAmount: Double {
        categorySummaries.reduce(0) { $0 + $1.totalAmount }
    }

    var totalTitle: String {
        selectedType == .income ? "収入合計" : "支出合計"
    }

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindCategories()
        bindCategorySummaries()
        bindLoadingState()
        bindErrorMessages()
    }

    func findCategory(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func deleteTransaction(_ transaction: TransactionModel) async {
        await transactionStore.delete(transaction)
    }

    func deleteCategory(_ category: CategoryModel) async {
        await categoryStore.delete(category)
    }

    func changeMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: startDate)
        else { return }
        startDate = newDate.startOfMonth
        endDate = newDate.endOfMonth
    }

    private func bindCategories() {
        Publishers.CombineLatest(
            categoryStore.categories,
            $selectedType
        )
        .map { categories, selectedType in
            categories.filter { $0.type == selectedType }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$categories)
    }

    private func bindCategorySummaries() {
        Publishers.CombineLatest4(
            transactionStore.transactions,
            categoryStore.categories,
            $selectedType,
            Publishers.CombineLatest($startDate, $endDate)
        )
        .map { [weak self] transactions, categories, selectedType, period in
            self?
                .makeCategorySummaries(
                    transactions: transactions,
                    categories: categories,
                    type: selectedType,
                    startDate: period.0,
                    endDate: period.1
                ) ?? []
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$categorySummaries)
    }

    private func bindLoadingState() {
        Publishers.CombineLatest(
            transactionStore.isLoading,
            categoryStore.isLoading
        )
        .map { $0 || $1 }
        .receive(on: DispatchQueue.main)
        .assign(to: &$isLoading)
    }

    private func bindErrorMessages() {
        Publishers.Merge(
            transactionStore.errorMessage,
            categoryStore.errorMessage
        )
        .receive(on: DispatchQueue.main)
        .assign(to: &$errorMessage)
    }

    private func makeCategorySummaries(
        transactions: [TransactionModel],
        categories: [CategoryModel],
        type: TransactionType,
        startDate: Date,
        endDate: Date
    ) -> [CategorySummary] {
        let filteredTransactions = transactions.filter {
            startDate <= $0.date && $0.date <= endDate && $0.type == type
        }

        let summaries =
            categories
            .filter { $0.type == type }
            .compactMap { category -> CategorySummary? in
                let related = filteredTransactions.filter { $0.categoryId == category.id }
                let total =
                    related
                    .map(\.amount)
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

        return summaries.sorted { $0.totalAmount > $1.totalAmount }
    }
}
