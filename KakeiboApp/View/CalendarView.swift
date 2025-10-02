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
        VStack {
            HStack {
                ForEach(["日", "月", "火", "水", "木", "金", "土"], id: \.self) { day in
                    HStack {
                        Spacer()
                        
                        Text(day)
                            .frame(maxWidth: .infinity)
                            .font(.subheadline)
                            .foregroundStyle(day == "日" ? .red : (day == "土") ? .blue : .primary)
                        
                        Spacer()
                    }
                }
            }

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
                                    .background(isToday(date) ? Color.blue.opacity(0.2) : Color.clear)
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

            Spacer()

        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }

    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "yyyy/MM/dd"
        return df
    }
}

#Preview {
    CalendarView()
}
