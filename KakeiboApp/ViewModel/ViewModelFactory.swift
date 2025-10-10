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
    @Published var inputViewModel: InputViewModel

    init() {
        let categoryRepository = CategoryRepository()
        let transactionRepository = TransactionRepository(categoryRepository: categoryRepository)
        let transactionViewModel = TransactionViewModel(
            transactionRepostory: transactionRepository,
            categoryRepository: categoryRepository
        )

        self.transactionViewModel = transactionViewModel
        self.categoryViewModel = CategoryViewModel(repository: categoryRepository)
        self.homeViewModel = HomeViewModel(transactionViewModel: transactionViewModel)
        self.inputViewModel = InputViewModel(transactionViewModel: transactionViewModel)
    }
}
