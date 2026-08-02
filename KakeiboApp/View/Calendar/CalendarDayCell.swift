//
//  CalendarDayCell.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/02
//
//

import SwiftUI

struct CalendarDayCell: View {
    let date: Date
    let summary: DailySummary?
    let isToday: Bool
    let isSelected: Bool
    let onSelect: () -> Void

    private let dayNumber: Int

    init(
        date: Date,
        summary: DailySummary?,
        isToday: Bool,
        isSelected: Bool,
        onSelect: @escaping () -> Void
    ) {
        self.date = date
        self.summary = summary
        self.isToday = isToday
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.dayNumber = Calendar.current.component(.day, from: date)
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 2) {
                Text("\(dayNumber)")
                    .font(.caption)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isToday ? Color.accentColor : Color.primary)
                    .frame(width: 24, height: 24)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15))
                        }
                    }

                VStack(spacing: 1) {
                    if let income = summary?.income, income > 0 {
                        Text(currencyString(income, allowedDigits: 0))
                            .font(.system(size: 9))
                            .foregroundStyle(Color.income)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Spacer()
                            .frame(height: 10)
                    }

                    if let expense = summary?.expense, expense > 0 {
                        Text(currencyString(expense, allowedDigits: 0))
                            .font(.system(size: 9))
                            .foregroundStyle(Color.expense)
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
