//
//  TransactionListByCategory.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/30
//
//

import SwiftUI

struct TransactionListByCategory: View {
    @ObservedObject var graphViewModel: GraphViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    let categoryID: UUID
    let onDeleteTransaction: (TransactionModel) -> Void

    var categorySummary: CategorySummary? {
        graphViewModel.categorySummaries.first {
            $0.categoryID == categoryID
        }
    }

    var body: some View {
        NavigationStack {

            VStack {
                if let summary = categorySummary {
                    VStack {
                        header(summary)
                        transactionList(summary.transactions)
                    }
                } else {
                    ZStack {
                        Color(.systemGroupedBackground)
                            .ignoresSafeArea()

                        VStack {
                            Text("取引なし")
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                            Image(systemName: "xmark.seal.fill")
                                .font(.custom("", size: 100))
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(graphViewModel.findCategory(id: categoryID)?.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            //            .toolbarBackground(categorySummary.color, for: .navigationBar)
            //            .toolbarBackground(.visible, for: .navigationBar)
            .padding(.horizontal, 16)
            .background(Color(.systemGroupedBackground))
            .alert("エラー", isPresented: .constant(graphViewModel.errorMessage != nil)) {
                Button("OK") {}
            } message: {
                if let errorMessage = graphViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    @ViewBuilder
    private func header(_ summary: CategorySummary) -> some View {
        HStack {
            Text("合計金額")
                .font(.title2)
                .fontWeight(.bold)

            Spacer()

            Text(currencyString(summary.totalAmount))
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func transactionList(_ transactions: [TransactionModel]) -> some View {
        ScrollView {
            ForEach(transactions) {
                transaction in
                NavigationLink(value: transaction) {
                    TransactionCardView(
                        transaction: transaction,
                        category: graphViewModel.findCategory(id: transaction.categoryId),
                        onDelete: onDeleteTransaction
                    )
                    .onTapGesture {
                        transactionInputViewModel.presentInputView(transaction)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
