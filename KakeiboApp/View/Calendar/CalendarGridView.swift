//
//  CalendarGridView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/02
//
//

import SwiftUI

struct CalendarGridView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel

    var body: some View {
        let daysInMonth = calculateDaysInMonth()
        let firstWeekday =
            daysInMonth.first.map {
                Calendar.current.component(.weekday, from: $0)
            } ?? 1

        VStack(spacing: 8) {
            weekdayHeader

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7),
                spacing: 4
            ) {
                ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
                    Color.clear
                        .frame(height: 56)
                }

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

    private var weekdayHeader: some View {
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
