//
//  ViewModelFactory.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/06
//
//

import Foundation

final class ViewModelFactory: ObservableObject {
    @Published var transactionViewModel: TransactionViewModel
    @Published var categoryViewModel: CategoryViewModel
    @Published var homeViewModel: HomeViewModel
    @Published var graphViewModel: GraphViewModel
    @Published var calendarViewModel: CalendarViewModel
    @Published var searchViewModel: SearchViewModel
    @Published var transactionInputViewModel: TransactionInputViewModel
    @Published var categoryInputViewModel: CategoryInputViewModel

    init() {
        let categoryRepository = CategoryRepository()
        let transactionRepository = TransactionRepository(categoryRepository: categoryRepository)
        let transactionViewModel = TransactionViewModel(
            transactionRepostory: transactionRepository,
            categoryRepository: categoryRepository
        )
        let categoryViewModel = CategoryViewModel(repository: categoryRepository)

        self.transactionViewModel = transactionViewModel
        self.categoryViewModel = categoryViewModel
        self.homeViewModel = HomeViewModel(
            transactionViewModel: transactionViewModel,
            categoryViewModel: categoryViewModel
        )
        self.graphViewModel = GraphViewModel(
            transactionViewModel: transactionViewModel,
            categoryViewModel: categoryViewModel
        )
        self.calendarViewModel = CalendarViewModel(
            transactionViewModel: transactionViewModel,
            categoryViewModel: categoryViewModel
        )
        self.searchViewModel = SearchViewModel(transactionRepository: transactionRepository)
        self.transactionInputViewModel = TransactionInputViewModel(
            transactionViewModel: transactionViewModel,
            categoryViewModel: categoryViewModel
        )
        self.categoryInputViewModel = CategoryInputViewModel(categoryViewModel: categoryViewModel)
    }
}
