//
//  CalendarView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import SwiftUI

struct CalendarView: View {
    @State private var currrentDate: Date = Date()
    @ObservedObject var calendarViewModel: CalendarViewModel
    private var daysInMonth: [Date] {
        guard let range = Calendar.current.range(of: .day, in: .month, for: currrentDate),
            let monthStart = Calendar.current.date(
                from: Calendar.current.dateComponents([.year, .month], from: currrentDate)
            )
        else {
            return []
        }

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
                HStack {
                    ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                        HStack {
                            Spacer()

                            Text(day)
                                .frame(maxWidth: .infinity)
                                .font(.subheadline)
                                .foregroundStyle(
                                    day == "日" ? .red : (day == "土") ? .blue : .primary
                                )

                            Spacer()
                        }
                    }
                }
                .padding(.top, 20)

                let firstWeekday = Calendar.current.component(
                    .weekday,
                    from: daysInMonth.first ?? Date()
                )
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                    ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                        Text("")
                    }

                    ForEach(daysInMonth, id: \.self) { date in
                        Button {

                        } label: {
                            VStack {
                                HStack {
                                    Spacer()

                                    Text("\(Calendar.current.component(.day, from: date))")
                                        .frame(maxWidth: .infinity, minHeight: 40)

                                        .background(
                                            isToday(date) ? Color.blue.opacity(0.2) : Color.clear
                                        )
                                        .clipShape(Circle())
                                        .foregroundStyle(isToday(date) ? .blue : .primary)

                                    Spacer()
                                }

                                Spacer()

                                HStack {
                                    Spacer()

                                    VStack(alignment: .leading) {
                                        if let income = calendarViewModel.dailySummaries[date]?
                                            .income
                                        {
                                            Text(
                                                currencyString(income, allowedDigits: 2)
                                            )
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.green)
                                        } else {
                                            Text("")
                                        }

                                        if let expense = calendarViewModel.dailySummaries[date]?
                                            .expense
                                        {
                                            Text(
                                                currencyString(expense, allowedDigits: 2)
                                            )
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.red)
                                        } else {
                                            Text("")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 20)

                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack {
                        ForEach(
                            calendarViewModel.filteredTransactions
                        ) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionCardView(
                                    transaction: transaction,
                                    category: calendarViewModel.categoryViewModel.find(
                                        id: transaction.categoryId
                                    ),
                                    onDelete: { transaction in
                                        calendarViewModel.transactionViewModel.delete(transaction)
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(15)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(.gray.opacity(0.15))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("カレンダー")
                        .font(.title.bold())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {

                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }

        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}

#Preview {
    CalendarView(calendarViewModel: ViewModelFactory().calendarViewModel)
}
