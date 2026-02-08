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
    @Published var dateRange: DateRange = DateRange(
        start: Date().startOfMonth,
        end: Date().endOfMonth
    )
    @Published var selectedType: TransactionType = .expense
    @Published var showFilterView = false

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

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindTransactions()
        bindLoadingState()
        bindErrorMessages()
    }

    func categoryFind(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func deleteTransaction(_ transaction: TransactionModel) async {
        await transactionStore.delete(transaction)
    }

    private func bindTransactions() {
        Publishers.CombineLatest3(
            transactionStore.transactions,
            $dateRange,
            $selectedType
        )
        .map { transactions, range, selectedType in
            transactions
                .filter { transaction in
                    range.start <= transaction.date && transaction.date <= range.end
                        && transaction.type == selectedType
                }
                .sorted { $0.date > $1.date }
        }
        .receive(on: DispatchQueue.main)
        .assign(to: &$filteredTransactions)
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
}
