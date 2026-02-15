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

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var dailySummaries: [Date: DailySummary] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var selectedDate: Date?
    @Published var currentDate: Date = Date()
    @Published var dateRange: DateRange = DateRange(
        start: Date().startOfMonth,
        end: Date().endOfMonth
    )

    var startDate: Binding<Date> {
        Binding(
            get: { self.dateRange.start },
            set: { newValue in
                self.dateRange = self.dateRange.withStart(newValue)
            }
        )
    }

    var endDate: Binding<Date> {
        Binding(
            get: { self.dateRange.end },
            set: { newValue in
                self.dateRange = self.dateRange.withEnd(newValue)
            }
        )
    }

    private var cancellables = Set<AnyCancellable>()

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindDailySummaries()
    }

    func changeMonth(by value: Int) {
        guard
            let newDate = Calendar.current.date(byAdding: .month, value: value, to: dateRange.start)
        else { return }
        dateRange = DateRange(start: newDate.startOfMonth, end: newDate.endOfMonth)
    }

    func delete(_ transaction: TransactionModel) async {
        isLoading = true
        do {
            try await transactionStore.delete(transaction)
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func category(for id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

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

    private func makeDailySummaries(
        transactions: [TransactionModel],
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
            let income =
                dailyTransactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }

            let expense =
                dailyTransactions
                .filter { $0.type == .expense }
                .reduce(0) { $0 + $1.amount }

            let date = Calendar.current.startOfDay(for: dailyTransactions[0].date)

            return DailySummary(
                date: date,
                income: income,
                expense: expense,
                transactions: dailyTransactions
            )
        }
    }
}
