//
//  HomeTransactionSectionView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/02
//
//

import SwiftUI

struct HomeTransactionSectionView: View {
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    var body: some View {
        Section {
            if homeViewModel.filteredTransactions.isEmpty {
                NoTransactionView()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(homeViewModel.filteredTransactions) { transaction in
                    TransactionCardView(
                        transaction: transaction,
                        category: homeViewModel.findCategory(id: transaction.categoryId)
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        transactionInputViewModel.presentInputView(for: transaction)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await homeViewModel.deleteTransaction(transaction)
                            }
                        } label: {
                            Label("", systemImage: "trash")
                        }
                    }
                }

                if homeViewModel.isLoading && !homeViewModel.filteredTransactions.isEmpty {
                    loadingIndicator
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
    }
}
