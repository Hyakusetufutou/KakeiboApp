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

                VStack(spacing: 16) {
                    if let summary {
                        DaySummaryView(
                            income: summary.income,
                            expense: summary.expense
                        )
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
                    } else {
                        List {
                            transactionListView(transactions: transactions)
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .background(Color(.systemGroupedBackground))
                        .refreshable {
                            await calendarViewModel.reload()
                        }
                    }
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
            }
        }
        .animation(.snappy, value: calendarViewModel.selectedDate)
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
