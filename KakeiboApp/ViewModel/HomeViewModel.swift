//
//  HomeViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/07
//
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    @Published var filteredTransactions: [TransactionModel] = []
    @Published var dateRange: DateRange = DateRange()
    @Published var selectedType: TransactionType = .expense
    @Published var showFilterView = false

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var isDefaultDateRange: Bool {
        let today = Date()
        return Calendar.current.isDate(
            dateRange.start,
            equalTo: today.startOfMonth,
            toGranularity: .day
        ) && Calendar.current.isDate(dateRange.end, equalTo: today.endOfMonth, toGranularity: .day)
    }

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindTransactions()
        bindError()
        Task {
            await self.transactionStore.load(from: dateRange.start, to: dateRange.end)
        }
    }

    // MARK: - Public Methods

    func categoryFind(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func deleteTransaction(_ transaction: TransactionModel) {
        isLoading = true
        defer { isLoading = false }

        Task {
            await transactionStore.delete(transaction)
        }
    }

    func reload() async {
        isLoading = true
        defer { isLoading = false }

        await transactionStore.load(from: dateRange.start, to: dateRange.end)
    }

    func clearError() {
        errorMessage = nil
    }

    func resetDateRangeIfNeeded(now: Date = Date()) {
        guard isDefaultDateRange else { return }

        guard !Calendar.current.isDate(now, equalTo: dateRange.start, toGranularity: .month)
        else { return }
        dateRange = DateRange()
    }

    // MARK: - Private Methods

    private func bindTransactions() {
        Publishers.CombineLatest3(
            transactionStore.transactions,
            $dateRange,
            $selectedType
        )
        .map { transactions, range, selectedType in
            transactions
                .filter {
                    range.start <= $0.date && $0.date <= range.end
                        && $0.type == selectedType
                }
                .sorted { $0.date > $1.date }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$filteredTransactions)
    }

    private func bindError() {
        transactionStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
