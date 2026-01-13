//
//  SearchView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/16
//
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    var body: some View {
        NavigationStack {
            VStack {
                if searchViewModel.resultTransactions
                    .isEmpty || searchViewModel.searchText.isEmpty
                {
                    Spacer()
                    Text("該当する取引がありません")
                    Spacer()
                } else {
                    ScrollView {
                        ForEach(
                            searchViewModel.resultTransactions
                        ) {
                            transaction in
                            NavigationLink(value: transaction) {
                                TransactionCardView(
                                    transaction: transaction,
                                    category: searchViewModel.findCategory(
                                        id: transaction.categoryId
                                    ),
                                    onDelete: { transaction in
                                        Task {
                                            await searchViewModel.deleteTransaction(transaction)
                                        }
                                    }
                                )
                                .onTapGesture {
                                    transactionInputViewModel.presentInputView(transaction)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
