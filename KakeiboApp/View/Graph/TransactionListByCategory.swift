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
                transactionList(summary)
            } else {
                VStack {
                    Spacer()
                    EmptyStateView(icon: "tray", message: "取引がありません")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(Color(.systemGroupedBackground))
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(graphViewModel.findCategory(id: categoryID)?.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .alert("エラー", isPresented: errorAlertBinding) {
            Button("OK") { graphViewModel.clearError() }
        } message: {
            if let errorMessage = graphViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Components

    private func transactionList(_ summary: CategorySummary) -> some View {
        List {
            Section {
                HStack {
                    Text("合計金額")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(currencyString(summary.totalAmount))
                        .font(.headline)
                        .monospacedDigit()
                }
            }

            Section {
                ForEach(summary.transactions) { transaction in
                    TransactionCardView(
                        transaction: transaction,
                        category: graphViewModel.findCategory(id: transaction.categoryId)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        transactionInputViewModel.presentInputView(for: transaction)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            onDeleteTransaction(transaction)
                        } label: {
                            Label("削除", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Helper

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { graphViewModel.errorMessage != nil },
            set: { if !$0 { graphViewModel.clearError() } }
        )
    }
}
