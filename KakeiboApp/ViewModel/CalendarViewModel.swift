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
    @Published var dailySummaries: [Date: DailySummary] = [:]
    @Published var dailyTransactions: [TransactionModel] = []
    @Published var filteredTransactions: [TransactionModel] = []

    @Published var selectedDate: Date?
    @Published var startDate: Date = .now.startOfMonth
    @Published var endDate: Date = .now.endOfMonth

    private var cancellables = Set<AnyCancellable>()

    let transactionViewModel: TransactionViewModel
    let categoryViewModel: CategoryViewModel

    init(transactionViewModel: TransactionViewModel, categoryViewModel: CategoryViewModel) {
        self.transactionViewModel = transactionViewModel
        self.categoryViewModel = categoryViewModel
        bindDailySummaries()
        bindTransactions()
        bindSelectedDate()
    }

    private func bindDailySummaries() {
        transactionViewModel.$transactions
            .combineLatest($startDate, $endDate)
            .map { transactions, startDate, endDate in
                transactions.filter { transaction in
                    startDate <= transaction.date && transaction.date <= endDate
                }
            }
            .map { transactions in
                Dictionary(grouping: transactions) {
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
                        for: dailyTransactions.first?.date ?? Date()
                    )
                    return DailySummary(
                        date: date,
                        income: income,
                        expense: expense,
                        transactions: dailyTransactions
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaries in
                self?.dailySummaries = summaries
                self?.updateSelectedDateTransactions()
            }
            .store(in: &cancellables)
    }

    private func bindTransactions() {
        transactionViewModel.$transactions
            .combineLatest($startDate, $endDate)
            .map { transactions, startDate, endDate in
                transactions.filter { transaction in
                    startDate <= transaction.date
                        && transaction.date <= endDate
                }
            }
            .assign(to: &$filteredTransactions)
    }

    private func bindSelectedDate() {
        $selectedDate
            .combineLatest($dailySummaries)
            .map { date, grouped in
                guard let date else { return [] }
                return grouped[Calendar.current.startOfDay(for: date)]?.transactions ?? []
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$dailyTransactions)
    }

    private func updateSelectedDateTransactions() {
        guard let selectedDate else { return }
        filteredTransactions =
            dailySummaries[Calendar.current.startOfDay(for: selectedDate)]?.transactions ?? []
    }

    func changeMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: startDate)
        else { return }
        startDate = newDate.startOfMonth
        endDate = newDate.endOfMonth
    }
}
