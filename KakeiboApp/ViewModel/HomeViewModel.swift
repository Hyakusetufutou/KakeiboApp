//
//  HomeViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/07
//
//

import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var filteredTransactions: [TransactionModel] = []
    @Published var startDate: Date = Date().startOfMonth
    @Published var endDate: Date = Date().endOfMonth
    @Published var selectedType: TransactionType = .expense
    @Published var showFilterView = false

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
        Publishers.CombineLatest4(
            transactionStore.transactions,
            $startDate,
            $endDate,
            $selectedType
        )
        .map { transactions, startDate, endDate, selectedType in
            transactions
                .filter { transaction in
                    startDate <= transaction.date && transaction.date <= endDate
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
