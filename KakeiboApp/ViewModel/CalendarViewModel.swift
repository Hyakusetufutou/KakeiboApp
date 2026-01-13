//
//  CalendarViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/03
//
//

import Foundation
import Combine

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    @Published private(set) var dailySummaries: [Date: DailySummary] = [:]
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    
    @Published var selectedDate: Date?
    @Published var currentDate: Date = Date()
    @Published var startDate: Date = Date().startOfMonth
    @Published var endDate: Date = Date().endOfMonth
    
    private var cancellables = Set<AnyCancellable>()
    
    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    
    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindDailySummaries()
    }
    
    func changeMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: startDate) else { return }
        startDate = newDate.startOfMonth
        endDate = newDate.endOfMonth
    }
    
    func delete(_ transaction: TransactionModel) async {
        isLoading = true
        await transactionStore.delete(transaction)
        isLoading = false
    }
    
    func category(for id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }
    
    private func bindDailySummaries() {
        Publishers.CombineLatest4(
            transactionStore.transactions,
            categoryStore.categories,
            $startDate,
            $endDate
        )
        .map { [weak self] transactions, _, startDate, endDate in
            self?.makeDailySummaries(
                transactions: transactions,
                startDate: startDate,
                endDate: endDate
            ) ?? [:]
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$dailySummaries)
        
        // エラーメッセージのバインディング
        Publishers.Merge(
            transactionStore.errorMessage,
            categoryStore.errorMessage
        )
        .receive(on: DispatchQueue.main)
        .assign(to: &$errorMessage)
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
            let income = dailyTransactions
                .filter { $0.type == .income }
                .reduce(0) { $0 + $1.amount }
            
            let expense = dailyTransactions
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
