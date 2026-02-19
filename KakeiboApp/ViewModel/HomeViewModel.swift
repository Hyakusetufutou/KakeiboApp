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
            set: { self.dateRange = self.dateRange.withStart($0) }
        )
    }

    var endDate: Binding<Date> {
        Binding(
            get: { self.dateRange.end },
            set: { self.dateRange = self.dateRange.withEnd($0) }
        )
    }

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindTransactions()
    }

    // MARK: - Public Methods

    func categoryFind(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func deleteTransaction(_ transaction: TransactionModel) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await transactionStore.delete(transaction)
        } catch {
            errorMessage = "削除に失敗しました: \(error.localizedDescription)"
        }
    }

    func clearError() {
        errorMessage = nil
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
}
