//
//  CalendarViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/03
//
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var dailySummaries: [Date: DailySummary] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var hasMoreData = true

    @Published var selectedDate: Date?
    @Published var currentDate: Date = Date()
    @Published var dateRange: DateRange = DateRange()

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindDailySummaries()
        bindHasMoreData()
        bindError()
    }

    // MARK: - Public Methods

    func changeMonth(by value: Int) {
        guard
            let newDate = Calendar.current.date(byAdding: .month, value: value, to: dateRange.start)
        else { return }
        dateRange = DateRange(start: newDate.startOfMonth, end: newDate.endOfMonth)
    }

    func delete(_ transaction: TransactionModel) async {
        isLoading = true
        defer { isLoading = false }

        await transactionStore.delete(transaction)
    }

    func category(for id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
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

    func resetDateRangeIfNeeded() {
        let today = Date()

        guard !Calendar.current.isDate(today, equalTo: dateRange.start, toGranularity: .month)
        else { return }
        dateRange = DateRange()
    }

    // MARK: - Private Methods

    private func bindDailySummaries() {
        Publishers.CombineLatest3(
            transactionStore.transactions,
            categoryStore.categories,
            $dateRange
        )
        .map { [weak self] transactions, _, range in
            self?
                .makeDailySummaries(
                    transactions: transactions,
                    startDate: range.start,
                    endDate: range.end
                ) ?? [:]
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$dailySummaries)
    }

    private func bindHasMoreData() {
        transactionStore.hasMoreData
            .receive(on: DispatchQueue.main)
            .assign(to: &$hasMoreData)
    }

    private func makeDailySummaries(
        transactions: [TransactionModel],
        startDate: Date,
        endDate: Date
    ) -> [Date: DailySummary] {
        let filtered = transactions.filter {
            startDate <= $0.date && $0.date <= endDate
        }

        return Dictionary(grouping: filtered) {
            Calendar.current.startOfDay(for: $0.date)
        }
        .mapValues { dailyTransactions in
            let income =
                dailyTransactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }

            let expense =
                dailyTransactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }

            return DailySummary(
                date: Calendar.current.startOfDay(for: dailyTransactions[0].date),
                income: income,
                expense: expense,
                transactions: dailyTransactions
            )
        }
    }

    private func bindError() {
        transactionStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
