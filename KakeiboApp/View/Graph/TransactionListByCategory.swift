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
                VStack {
                    Spacer()
                    EmptyStateView(icon: "tray", message: "取引がありません")
                    Spacer()
                }
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
        List {
            ForEach(transactions) { transaction in
                TransactionCardView(
                    transaction: transaction,
                    category: graphViewModel.findCategory(id: transaction.categoryId),
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                .contentShape(Rectangle())
                .onTapGesture {
                    transactionInputViewModel.presentInputView(for: transaction)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        onDeleteTransaction(transaction)
                    } label: {
                        Label("", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helper

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { graphViewModel.errorMessage != nil },
            set: { if !$0 { graphViewModel.clearError() } }
        )
    }
}
