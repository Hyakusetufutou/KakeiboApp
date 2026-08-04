//
//  GraphViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/28
//
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class GraphViewModel: ObservableObject {
    // MARK: - State
    @Published private(set) var categorySummaries: [CategorySummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasMoreData = true

    @Published var selectedType: TransactionType = .expense
    @Published var dateRange: DateRange = DateRange()

    // MARK: - Computed Properties

    var totalAmount: Decimal {
        categorySummaries.reduce(0) { $0 + $1.totalAmount }
    }

    var totalTitle: String {
        selectedType == .income ? "収入合計" : "支出合計"
    }

    // MARK: - Dependencies
    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol

    // MARK: - Init
    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindCategorySummaries()
        bindHasMoreData()
        bindError()
    }

    // MARK: - Public Methods

    func findCategory(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func deleteTransaction(_ transaction: TransactionModel) async {
        isLoading = true
        defer { isLoading = false }

        await transactionStore.delete(transaction)
    }

    func changeMonth(by value: Int) {
        guard
            let newDate = Calendar.current.date(byAdding: .month, value: value, to: dateRange.start)
        else { return }
        dateRange = DateRange(start: newDate.startOfMonth, end: newDate.endOfMonth)
    }

    func loadMore() async {
        guard hasMoreData else { return }

        isLoading = true
        defer { isLoading = false }

        await transactionStore.loadMore()
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }

        await transactionStore.reload()
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func bindCategorySummaries() {
        Publishers.CombineLatest4(
            transactionStore.transactions,
            categoryStore.categories,
            $selectedType,
            $dateRange
        )
        .map { [weak self] transactions, categories, selectedType, range in
            self?
                .makeCategorySummaries(
                    transactions: transactions,
                    categories: categories,
                    type: selectedType,
                    startDate: range.start,
                    endDate: range.end
                ) ?? []
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$categorySummaries)
    }

    private func bindHasMoreData() {
        transactionStore.hasMoreData
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasMoreData)
    }

    private func makeCategorySummaries(
        transactions: [TransactionModel],
        categories: [CategoryModel],
        type: TransactionType,
        startDate: Date,
        endDate: Date
    ) -> [CategorySummary] {
        let filtered = transactions.filter {
            startDate <= $0.date && $0.date <= endDate && $0.type == type
        }

        return
            categories
            .filter { $0.type == type }
            .compactMap { category -> CategorySummary? in
                let related = filtered.filter { $0.categoryId == category.id }
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
                    color: category.color.color,
                    transactions: related
                )
            }
            .sorted { $0.totalAmount > $1.totalAmount }
    }

    private func bindError() {
        transactionStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
