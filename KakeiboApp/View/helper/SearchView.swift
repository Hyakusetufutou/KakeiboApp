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
    @ObservedObject var categoryViewModel: CategoryViewModel
    @ObservedObject var transactionViewModel: TransactionViewModel
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
                        .padding()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(.gray.opacity(0.1))
        }
        .overlay(alignment: .topLeading) {
            VStack {
                Text("検索")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    SearchView(
        searchViewModel: ViewModelFactory().searchViewModel,
        categoryViewModel: ViewModelFactory().categoryViewModel,
        transactionViewModel: ViewModelFactory().transactionViewModel,
        transactionInputViewModel: ViewModelFactory().transactionInputViewModel
    )
}
