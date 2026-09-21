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

                if let summary {
                    DaySummaryView(
                        income: summary.income,
                        expense: summary.expense
                    )
                    .listRowSeparatorHiddenAndBackgroundClear()
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
                }

                if transactions.isEmpty {
                    VStack {
                        Spacer()
                        EmptyStateView(
                            icon: "calendar.badge.clock",
                            message: "この日の取引はありません"
                        )
                        Spacer()
                    }
                    .frame(minHeight: 160)
                    .listRowSeparatorHiddenAndBackgroundClear()
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                } else {
                    transactionListView(transactions: transactions)
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(AppTheme.background)
                }
            } else {
                VStack {
                    Spacer()
                    EmptyStateView(
                        icon: "hand.tap",
                        message: "日付を選択してください"
                    )
                    Spacer()
                }
                .frame(minHeight: 200)
                .listRowSeparatorHiddenAndBackgroundClear()
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }

    @ViewBuilder
    private func transactionListView(transactions: [TransactionModel]) -> some View {
        Section {
            ForEach(transactions) { transaction in
                TransactionCardView(
                    transaction: transaction,
                    category: calendarViewModel.category(for: transaction.categoryId)
                )
                .frame(maxWidth: .infinity)
                .listRowSeparatorHiddenAndBackgroundClear()
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .contentShape(Rectangle())
                .onTapGesture {
                    transactionInputViewModel.presentInputView(for: transaction)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await calendarViewModel.delete(transaction)
                        }
                    } label: {
                        Label("", systemImage: "trash")
                    }
                }
            }
        }
    }
}
