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

    private let transactionRepository: TransactionRepository
    private let categoryRepository: CategoryRepository

    init(transactionRepository: TransactionRepository, categoryRepository: CategoryRepository) {
        self.transactionRepository = transactionRepository
        self.categoryRepository = categoryRepository
        fetch()
    }

    func changeMonth(by value: Int) {
        guard let newDate = Calendar.current.date(byAdding: .month, value: value, to: startDate)
        else { return }
        startDate = newDate.startOfMonth
        endDate = newDate.endOfMonth
        fetch()
    }

    func delete(_ transaction: TransactionModel) {
        switch transactionRepository.delete(transaction) {
        case .success(()):
            return
        case .failure(_):
            return
        }
    }

    func category(for id: UUID) -> CategoryModel? {
        switch categoryRepository.fetch(by: id) {
        case .success(let category):
            return category
        case .failure(_):
            return nil
        }
    }

    private func bindRepository() {
        transactionRepository.didChange
            .sink { [weak self] in
                self?.fetch()
            }
            .store(in: &cancellables)
    }

    private func fetch() {
        let result = transactionRepository.fetch(from: startDate, to: endDate)
        switch result {
        case .success(let transactions):
            dailySummaries = makeDailySummaries(from: transactions)
        case .failure:
            dailySummaries = [:]
        }
    }

    private func makeDailySummaries(from transactions: [TransactionModel]) -> [Date: DailySummary] {
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
}
