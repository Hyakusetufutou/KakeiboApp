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
    @State private var startDate: Date = .now.startOfMonth
    @State private var endDate: Date = .now.endOfMonth
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

    var body: some View {
        NavigationStack {
            VStack {
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
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
                                    Text("10000")
                                        .font(.caption2)

                                    Spacer()
                                }

                            }
                        }

                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 20)


                ScrollView {
                    LazyVStack {
                        FilterTransactionsView(startDate: startDate, endDate: endDate) {
                            transactions in
                            ForEach(
                                transactions
                            ) { transaction in
                                NavigationLink(value: transaction) {
                                    TransactionCardView(transaction: transaction)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .background(.gray.opacity(0.15))
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
    CalendarView()
}
