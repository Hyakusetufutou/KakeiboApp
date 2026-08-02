//
//  CalendarSelectedDateContentView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/02
//
//

import SwiftUI

struct CalendarSelectedDateContentView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    var body: some View {
        Group {
            if let selectedDate = calendarViewModel.selectedDate {
                let selected = Calendar.current.startOfDay(for: selectedDate)
                let summary = calendarViewModel.dailySummaries[selected]
                let transactions = summary?.transactions ?? []

                VStack(spacing: 12) {
                    if let summary {
                        DaySummaryView(
                            income: summary.income,
                            expense: summary.expense
                        )
                    }

                    if transactions.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.clock",
                            message: "この日の取引はありません"
                        )
                    } else {
                        transactionListView(transactions: transactions)
                    }
                }
            } else {
                EmptyStateView(
                    icon: "hand.tap",
                    message: "日付を選択してください"
                )
            }
        }
    }

    private func transactionListView(transactions: [TransactionModel]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(transactions) { transaction in
                TransactionCardView(
                    transaction: transaction,
                    category: calendarViewModel.category(for: transaction.categoryId)
                )
                .onTapGesture {
                    transactionInputViewModel.presentInputView(for: transaction)
                }
            }
        }
    }
}
