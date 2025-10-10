//
//  HomeViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/07
//
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var startDate: Date = .now.startOfMonth
    @Published var endDate: Date = .now.endOfMonth
    @Published var selectedType: TransactionType = .expense
    @Published var showFilterView: Bool = false

    private let transactionViewModel: TransactionViewModel

    init(transactionViewModel: TransactionViewModel) {
        self.transactionViewModel = transactionViewModel
    }

}
