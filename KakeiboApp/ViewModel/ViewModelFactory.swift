//
//  ViewModelFactory.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/06
//
//

import Foundation

final class ViewModelFactory: ObservableObject {
    @Published var homeViewModel: HomeViewModel
    @Published var graphViewModel: GraphViewModel
    @Published var calendarViewModel: CalendarViewModel
    @Published var searchViewModel: SearchViewModel
    @Published var transactionInputViewModel: TransactionInputViewModel
    @Published var categoryInputViewModel: CategoryInputViewModel

    init() {
        let categoryRepository = CategoryRepository()
        let transactionRepository = TransactionRepository(categoryRepository: categoryRepository)

        let categoryStore = CategoryStore(categoryRepository: categoryRepository)
        let transactionStore = TransactionStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository
        )

        self.homeViewModel = HomeViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        self.graphViewModel = GraphViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        self.calendarViewModel = CalendarViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        self.searchViewModel = SearchViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        self.transactionInputViewModel = TransactionInputViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        self.categoryInputViewModel = CategoryInputViewModel(categoryStore: categoryStore)
    }
}
