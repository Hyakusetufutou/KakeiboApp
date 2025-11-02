//
//  TransactionListByCategory.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/30
//
//

import SwiftUI

struct TransactionListByCategory: View {
    let categorySummary: CategorySummary

    @ObservedObject var categoryViewModel: CategoryViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    @Environment(\.dismiss) var dismiss

    init(
        categorySummary: CategorySummary,
        categoryViewModel: CategoryViewModel,
        transactionViewModel: TransactionViewModel,
        transactionInputViewModel: TransactionInputViewModel
    ) {
        self.categorySummary = categorySummary
        self.categoryViewModel = categoryViewModel
        self.transactionViewModel = transactionViewModel
        self.transactionInputViewModel = transactionInputViewModel
    }

    var body: some View {
        NavigationStack {
            HStack {
                Text("合計金額")

                Spacer()

                Text(String(Int(categorySummary.totalAmount)))
            }
            ScrollView {
                ForEach(
                    categorySummary.transactions
                ) {
                    transaction in
                    NavigationLink(value: transaction) {
                        TransactionCardView(
                            transaction: transaction,
                            category: categoryViewModel.find(id: transaction.categoryId),
                            onDelete: { transaction in
                                transactionViewModel.delete(transaction)
                            }
                        )
                        .onTapGesture {
                            transactionInputViewModel.presentInputView(transaction)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(categorySummary.categoryName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            //            .toolbarBackground(categorySummary.color, for: .navigationBar)
            //            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}
