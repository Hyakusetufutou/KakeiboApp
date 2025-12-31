//
//  SearchViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/16
//
//

import Foundation
import Combine

class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var filterText: String = ""
    @Published var resultTransactions: [TransactionModel] = []

    let transactionRepository: TransactionRepository
    private var cancellables = Set<AnyCancellable>()

    init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
        setupSearchPipeline()
    }

    private func setupSearchPipeline() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.performSearch(text)
            }
            .store(in: &cancellables)
    }

    private func performSearch(_ text: String) {
        guard !text.isEmpty else {
            resultTransactions = []
            return
        }
        switch transactionRepository.search(text: text) {
        case .success(let items):
            DispatchQueue.main.async {
                self.resultTransactions = items
            }
        case .failure(_):
            DispatchQueue.main.async {
                self.resultTransactions = []
            }
        }
    }
}
