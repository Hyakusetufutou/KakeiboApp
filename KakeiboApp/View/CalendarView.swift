//
//  CalendarView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    private var daysInMonth: [Date] {
        guard
            let range = Calendar.current.range(
                of: .day,
                in: .month,
                for: calendarViewModel.currentDate
            ),
            let monthStart = Calendar.current.date(
                from: Calendar.current.dateComponents(
                    [.year, .month],
                    from: calendarViewModel.currentDate
                )
            )
        else { return [] }

        return range.compactMap { day -> Date? in
            Calendar.current.date(byAdding: .day, value: day - 1, to: monthStart)
        }
    }

    init(calendarViewModel: CalendarViewModel, transactionInputViewModel: TransactionInputViewModel)
    {
        self.calendarViewModel = calendarViewModel
        self.transactionInputViewModel = transactionInputViewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                    Section {
                        VStack(spacing: 0) {
                            // MARK: - 月切り替え
                            ChangeMonthView(
                                date: $calendarViewModel.currentDate,
                                onPreviousMonth: {
                                    calendarViewModel.changeMonth(by: -1)
                                    calendarViewModel.currentDate = Calendar.current.date(
                                        byAdding: .month,
                                        value: -1,
                                        to: calendarViewModel.currentDate
                                    )!
                                },
                                onNextMonth: {
                                    calendarViewModel.changeMonth(by: 1)
                                    calendarViewModel.currentDate = Calendar.current.date(
                                        byAdding: .month,
                                        value: 1,
                                        to: calendarViewModel.currentDate
                                    )!
                                }
                            )

                            calendarUnit()

                            calendarTransactionList()
                                .background(Color(.systemGroupedBackground))
                        }
                    } header: {
                        Text("カレンダー")
                            .font(.title2.bold())
                            .hSpacing(.leading)
                            .padding(.horizontal, 16)
                    }

                }
            }
            .background(Color(.systemGroupedBackground))
        }

    }

    @ViewBuilder
    func calendarUnit() -> some View {
        // MARK: - カレンダー本体
        let firstWeekday = Calendar.current.component(
            .weekday,
            from: daysInMonth.first ?? Date()
        )

        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 2) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                Text(day)
                    .frame(maxWidth: .infinity)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(day == "日" ? .red : (day == "土" ? .blue : .primary))
            }
            // 先頭の空白セルを同じ高さで埋める
            ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                Color.clear
                    .frame(height: 60)
            }

            ForEach(daysInMonth, id: \.self) { date in
                let summary = calendarViewModel.dailySummaries[
                    Calendar.current.startOfDay(for: date)
                ]
                let isToday = Calendar.current.isDateInToday(date)
                let isSelected = Calendar.current.isDate(
                    date,
                    inSameDayAs: calendarViewModel.selectedDate ?? Date.distantPast
                )

                Button {
                    calendarViewModel.selectedDate = date
                } label: {
                    VStack(spacing: 2) {
                        // 日付
                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.callout)
                            .fontWeight(isToday ? .bold : .regular)
                            .foregroundStyle(isToday ? .blue : .primary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(
                                        isSelected ? Color.blue.opacity(0.2) : Color.clear
                                    )
                            )

                        // 収支（高さ固定）
                        VStack(spacing: 1) {
                            if let income = summary?.income, income > 0 {
                                Text("\(currencyString(income, allowedDigits: 0))")
                                    .font(.caption)
                                    .foregroundStyle(.green)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            } else {
                                Text(" ")
                                    .font(.caption)
                            }

                            if let expense = summary?.expense, expense > 0 {
                                Text("\(currencyString(expense, allowedDigits: 0))")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            } else {
                                Text(" ")
                                    .font(.caption)
                            }
                        }
                        .frame(height: 22)
                    }
                    .frame(maxWidth: .infinity, minHeight: 32)
                    //                            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    func calendarTransactionList() -> some View {
        if let selectedDate = calendarViewModel.selectedDate {
            let selected = Calendar.current.startOfDay(for: selectedDate)
            let summary = calendarViewModel.dailySummaries[selected]
            let transactions =
                calendarViewModel.dailySummaries[selected]?.transactions ?? []

            if let summary {
                DaySummaryView(income: summary.income, expense: summary.expense)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }

            if transactions.isEmpty {
                Text("この日の取引はありません")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 30)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(transactions) { transaction in
                        TransactionCardView(
                            transaction: transaction,
                            category: calendarViewModel.category(
                                for: transaction.categoryId
                            ),
                            onDelete: { transaction in
                                calendarViewModel.delete(
                                    transaction
                                )
                            }
                        )
                        .onTapGesture {
                            transactionInputViewModel.presentInputView(transaction)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 6)
            }
        } else {
            Text("日付を選択してください")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 30)
        }
    }
}
