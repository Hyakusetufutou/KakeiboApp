//
//  CalendarViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/03
//
//

import Foundation
import Combine

class CalendarViewModel: ObservableObject {
    @Published private(set) var dailySummaries: [Date: DailySummary] = [:]

    @Published var selectedDate: Date?
    @Published var currentDate: Date = Date()
    @Published var startDate: Date = .now.startOfMonth
    @Published var endDate: Date = .now.endOfMonth

    private var cancellables = Set<AnyCancellable>()

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindDailySummaries()
    }

    func changeMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: startDate)
        else { return }
        startDate = newDate.startOfMonth
        endDate = newDate.endOfMonth
    }

    func delete(_ transaction: TransactionModel) {
        transactionStore.delete(transaction)
    }

    func category(for id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    private func bindDailySummaries() {
        Publishers.CombineLatest3(
            transactionStore.transactions,
            categoryStore.categories,
            Publishers.CombineLatest($startDate, $endDate)
        )
        .map { [weak self] transactions, categories, period in
            self?
                .makeDailySummaries(
                    transactions: transactions,
                    categories: categories,
                    startDate: period.0,
                    endDate: period.1
                ) ?? [:]
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$dailySummaries)

    }

    private func makeDailySummaries(
        transactions: [TransactionModel],
        categories: [CategoryModel],
        startDate: Date,
        endDate: Date
    ) -> [Date: DailySummary] {

        let filteredTransactions = transactions.filter {
            startDate <= $0.date && $0.date <= endDate
        }

        return Dictionary(grouping: filteredTransactions) {
            Calendar.current.startOfDay(for: $0.date)
        }
        .mapValues { dailyTransactions -> DailySummary in
            let income = dailyTransactions.filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }

            let expense =
                dailyTransactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }

            let date = Calendar.current.startOfDay(
                for: dailyTransactions[0].date
            )
            return DailySummary(
                date: date,
                income: income,
                expense: expense,
                transactions: dailyTransactions
            )
        }
    }
}
