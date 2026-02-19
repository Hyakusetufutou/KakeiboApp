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

    init(calendarViewModel: CalendarViewModel, transactionInputViewModel: TransactionInputViewModel)
    {
        self.calendarViewModel = calendarViewModel
        self.transactionInputViewModel = transactionInputViewModel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 固定ヘッダー
                headerView()

                // 固定カレンダー部分
                VStack(spacing: 0) {
                    monthNavigationView()
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    calendarGridView()
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .background(Color(.systemGroupedBackground))

                // スクロール可能な取引リスト
                ScrollView(.vertical, showsIndicators: false) {
                    selectedDateContentView()
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
            }
            .background(Color(.systemGroupedBackground))
            .overlay {
                if calendarViewModel.isLoading {
                    loadingOverlay()
                }
            }
            .alert("エラー", isPresented: .constant(calendarViewModel.errorMessage != nil)) {
                Button("OK") {
                }
            } message: {
                if let errorMessage = calendarViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Header View
    @ViewBuilder
    private func headerView() -> some View {
        HStack {
            Text("カレンダー")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Rectangle()
                .fill(Color(.systemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                .ignoresSafeArea(edges: .top)
        }
    }

    // MARK: - Month Navigation
    @ViewBuilder
    private func monthNavigationView() -> some View {
        ChangeMonthView(
            date: $calendarViewModel.currentDate,
            onPreviousMonth: {
                calendarViewModel.changeMonth(by: -1)
                calendarViewModel.currentDate =
                    Calendar.current.date(
                        byAdding: .month,
                        value: -1,
                        to: calendarViewModel.currentDate
                    ) ?? calendarViewModel.currentDate
            },
            onNextMonth: {
                calendarViewModel.changeMonth(by: 1)
                calendarViewModel.currentDate =
                    Calendar.current.date(
                        byAdding: .month,
                        value: 1,
                        to: calendarViewModel.currentDate
                    ) ?? calendarViewModel.currentDate
            }
        )
    }

    // MARK: - Calendar Grid
    @ViewBuilder
    private func calendarGridView() -> some View {
        let daysInMonth = calculateDaysInMonth()
        let firstWeekday = Calendar.current.component(
            .weekday,
            from: daysInMonth.first ?? Date()
        )

        VStack(spacing: 8) {
            // 曜日ヘッダー
            weekdayHeader()

            // カレンダーグリッド
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                // 月初めの空白
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                    Color.clear
                        .frame(height: 56)
                }

                // 日付セル
                ForEach(daysInMonth, id: \.self) { date in
                    CalendarDayCell(
                        date: date,
                        summary: calendarViewModel.dailySummaries[
                            Calendar.current.startOfDay(for: date)
                        ],
                        isToday: Calendar.current.isDateInToday(date),
                        isSelected: Calendar.current.isDate(
                            date,
                            inSameDayAs: calendarViewModel.selectedDate ?? Date.distantPast
                        ),
                        onSelect: {
                            calendarViewModel.selectedDate = date
                        }
                    )
                }
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func weekdayHeader() -> some View {
        HStack(spacing: 4) {
            ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                Text(day)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(weekdayColor(for: day))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func weekdayColor(for day: String) -> Color {
        switch day {
        case "日": return .red
        case "土": return .blue
        default: return .secondary
        }
    }

    // MARK: - Selected Date Content
    @ViewBuilder
    private func selectedDateContentView() -> some View {
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
                    emptyTransactionView()
                } else {
                    transactionListView(transactions: transactions)
                }
            }
        } else {
            emptySelectionView()
        }
    }

    @ViewBuilder
    private func transactionListView(transactions: [TransactionModel]) -> some View {
        LazyVStack(spacing: 8) {
            ForEach(transactions) { transaction in
                TransactionCardView(
                    transaction: transaction,
                    category: calendarViewModel.category(for: transaction.categoryId),
                    onDelete: { transaction in
                        Task {
                            await calendarViewModel.delete(transaction)
                        }
                    }
                )
                .onTapGesture {
                    transactionInputViewModel.presentInputView(for: transaction)
                }
            }
        }
    }

    @ViewBuilder
    private func emptyTransactionView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.4))

            Text("この日の取引はありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func emptySelectionView() -> some View {
        VStack(spacing: 12) {
            Image(systemName: "hand.tap")
                .font(.system(size: 40))
                .foregroundStyle(.secondary.opacity(0.4))

            Text("日付を選択してください")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    @ViewBuilder
    private func loadingOverlay() -> some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()

            ProgressView()
                .scaleEffect(1.5)
                .tint(.primary)
        }
    }

    // MARK: - Helper Methods
    private func calculateDaysInMonth() -> [Date] {
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
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let date: Date
    let summary: DailySummary?
    let isToday: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    private var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                // 日付
                Text("\(dayNumber)")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? .blue : .primary)
                    .frame(width: 24, height: 24)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(.blue.opacity(0.15))
                        }
                    }

                // 収支表示
                VStack(spacing: 1) {
                    if let income = summary?.income, income > 0 {
                        Text(currencyString(income, allowedDigits: 0))
                            .font(.system(size: 9))
                            .foregroundStyle(.green)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }

                    if let expense = summary?.expense, expense > 0 {
                        Text(currencyString(expense, allowedDigits: 0))
                            .font(.system(size: 9))
                            .foregroundStyle(.red)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                }
            }
        }
        .buttonStyle(.plain)
    }
}
