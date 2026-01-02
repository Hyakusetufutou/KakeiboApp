//
//  TransactionListByCategory.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/30
//
//

import SwiftUI

struct TransactionListByCategory: View {

    @ObservedObject var transactionInputViewModel: TransactionInputViewModel
    let categorySummary: CategorySummary
    let onDeleteTransaction: (TransactionModel) -> Void
    let onFindCategory: (UUID) -> CategoryModel?

    @Environment(\.dismiss) var dismiss

    init(
        transactionInputViewModel: TransactionInputViewModel,
        categorySummary: CategorySummary,
        onDeleteTransaction: @escaping (TransactionModel) -> Void,
        onFindCategory: @escaping (UUID) -> CategoryModel?
    ) {
        self.transactionInputViewModel = transactionInputViewModel
        self.categorySummary = categorySummary
        self.onDeleteTransaction = onDeleteTransaction
        self.onFindCategory = onFindCategory
    }

    var body: some View {
        NavigationStack {
            HStack {
                Text("合計金額")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text(currencyString(categorySummary.totalAmount))
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.vertical, 12)

            VStack {
                if !categorySummary.transactions.isEmpty {
                    ScrollView {
                        ForEach(
                            categorySummary.transactions
                        ) {
                            transaction in
                            NavigationLink(value: transaction) {
                                TransactionCardView(
                                    transaction: transaction,
                                    category: onFindCategory(transaction.categoryId),
                                    onDelete: onDeleteTransaction
                                )
                                .onTapGesture {
                                    transactionInputViewModel.presentInputView(transaction)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    VStack(alignment: .center) {
                        Spacer()

                        Text("取引なし")
                            .font(.title2)

                        Spacer()
                    }
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
        .padding(.horizontal, 16)
        .background(.gray.opacity(0.15))
    }
}
