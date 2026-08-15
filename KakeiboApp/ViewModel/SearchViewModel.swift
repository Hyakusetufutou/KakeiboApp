//
//  SearchViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/16
//
//

import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var isPresented = false
    @Published var searchText = ""
    @Published private(set) var isLoading = false
    @Published private(set) var resultTransactions: [TransactionModel] = []
    @Published private(set) var errorMessage: String?

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var cancellables = Set<AnyCancellable>()
    private var searchTask: Task<Void, Never>?

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        setupSearchPipeline()
        bindError()
    }

    // MARK: - Public Methods

    func deleteTransaction(_ transaction: TransactionModel) async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await transactionStore.delete(transaction)
        } catch {
            errorMessage = ErrorMapper.message(for: error)
        }
    }

    func findCategory(id: UUID) -> CategoryModel? {
        categoryStore.find(id: id)
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods

    private func setupSearchPipeline() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }

    private func performSearch(_ text: String) {
        searchTask?.cancel()

        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            resultTransactions = []
            return
        }

        searchTask = Task {
            do {
                let results = try await transactionStore.search(text: text)

                guard !Task.isCancelled else { return }
                resultTransactions = results
            } catch is CancellationError {

            } catch {
                let message = ErrorMapper.message(for: error)
                self.errorMessage = "検索に失敗しました: \(message)"
                self.resultTransactions = []
            }
        }
    }

    private func bindError() {
        transactionStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}
