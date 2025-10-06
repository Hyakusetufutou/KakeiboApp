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

    init() {
        let categoryRepository = CategoryRepository()
        let transactionRepository = TransactionRepository(categoryRepository: categoryRepository)
        self.transactionViewModel = TransactionViewModel(
            transactionRepostory: transactionRepository,
            categoryRepository: categoryRepository
        )
        self.categoryViewModel = CategoryViewModel(repository: categoryRepository)
    }
}
