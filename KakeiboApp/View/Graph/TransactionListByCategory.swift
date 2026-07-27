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

    private var categorySummary: CategorySummary? {
        graphViewModel.categorySummaries.first { $0.categoryID == categoryID }
    }

    var body: some View {
        Group {
            if let summary = categorySummary {
                VStack(spacing: 0) {
                    header(summary)
                        .padding(.horizontal, 16)
                    transactionList(summary.transactions)
                }
            } else {
                EmptyStateView(icon: "tray", message: "取引がありません")
            }
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(graphViewModel.findCategory(id: categoryID)?.name ?? "")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .alert("エラー", isPresented: errorAlertBinding) {
            Button("OK") { graphViewModel.clearError() }
        } message: {
            if let errorMessage = graphViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Components

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

    private func transactionList(_ transactions: [TransactionModel]) -> some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(transactions) { transaction in
                    TransactionCardView(
                        transaction: transaction,
                        category: graphViewModel.findCategory(id: transaction.categoryId),
                        //                        onDelete: onDeleteTransaction
                    )
                    .onTapGesture {
                        transactionInputViewModel.presentInputView(for: transaction)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Helper

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { graphViewModel.errorMessage != nil },
            set: { if !$0 { graphViewModel.clearError() } }
        )
    }
}
