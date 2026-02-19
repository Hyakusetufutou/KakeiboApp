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

                    if searchViewModel.searchText.isEmpty {
                        Text("キーワードを入力してください")
                    } else {
                        Text("該当する取引がありません")
                    }
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
                                    transactionInputViewModel.presentInputView(for: transaction)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        searchViewModel.isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(width: 44, height: 44)
                    }
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchViewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "取引を検索"
            )
        }
    }

}
