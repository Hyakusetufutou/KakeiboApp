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

    init(calendarViewModel: CalendarViewModel) {
        self.calendarViewModel = calendarViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - 月切り替え
                HStack {
                    Button {
                        calendarViewModel.changeMonth(by: -1)
                        calendarViewModel.currentDate = Calendar.current.date(
                            byAdding: .month,
                            value: -1,
                            to: calendarViewModel.currentDate
                        )!
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text(format(date: calendarViewModel.currentDate, format: "yyyy年 M月"))
                        .font(.title3.bold())

                    Spacer()

                    Button {
                        calendarViewModel.changeMonth(by: 1)
                        calendarViewModel.currentDate = Calendar.current.date(
                            byAdding: .month,
                            value: 1,
                            to: calendarViewModel.currentDate
                        )!
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                Divider()

                // MARK: - カレンダー本体
                let firstWeekday = Calendar.current.component(
                    .weekday,
                    from: daysInMonth.first ?? Date()
                )

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
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
                            withAnimation(.easeInOut) {
                                calendarViewModel.selectedDate = date
                            }
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
                                        Text("+\(currencyString(income, allowedDigits: 0))")
                                            .font(.caption2)
                                            .foregroundStyle(.green)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                    } else {
                                        Text(" ")
                                            .font(.caption2)
                                    }

                                    if let expense = summary?.expense, expense > 0 {
                                        Text("-\(currencyString(expense, allowedDigits: 0))")
                                            .font(.caption2)
                                            .foregroundStyle(.red)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.6)
                                    } else {
                                        Text(" ")
                                            .font(.caption2)
                                    }
                                }
                                .frame(height: 22)
                            }
                            .frame(maxWidth: .infinity, minHeight: 60)
                            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                Divider()

                // MARK: - トランザクションリスト
                ScrollView(.vertical, showsIndicators: true) {
                    if let selectedDate = calendarViewModel.selectedDate {
                        let selected = Calendar.current.startOfDay(for: selectedDate)
                        let transactions =
                            calendarViewModel.dailySummaries[selected]?.transactions ?? []

                        if transactions.isEmpty {
                            Text("この日の取引はありません")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, 30)
                        } else {
                            LazyVStack(spacing: 10) {
                                ForEach(transactions) { transaction in
                                    TransactionCardView(
                                        transaction: transaction,
                                        category: calendarViewModel.categoryViewModel.find(
                                            id: transaction.categoryId
                                        ),
                                        onDelete: { transaction in
                                            calendarViewModel.transactionViewModel.delete(
                                                transaction
                                            )
                                        }
                                    )
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
                .background(Color(.systemGroupedBackground))
            }
            .background(.gray.opacity(0.1))
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
