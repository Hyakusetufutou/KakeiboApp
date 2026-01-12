//
//  FilterTransactionsView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import SwiftUI

struct FilterTransactionsView<Content: View>: View {
    var content: ([TransactionModel]) -> Content
    private var transactions: [TransactionModel]
    @EnvironmentObject var appViewModel: ViewModelFactory

    init(
        startDate: Date,
        endDate: Date,
        @ViewBuilder content: @escaping ([TransactionModel]) -> Content
    ) {
        transactions = [.mock1, .mock2, .mock3]
        self.content = content
    }

    var body: some View {
        content(transactions)
    }
}
