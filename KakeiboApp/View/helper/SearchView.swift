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
                                        searchViewModel.deleteTransaction(transaction)
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
            .background(.gray.opacity(0.1))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack {
                        Text("検索")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}
