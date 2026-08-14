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
            VStack(spacing: 3) {
                Text("\(dayNumber)")
                    .font(.callout)
                    .fontWeight(isToday || isSelected ? .semibold : .regular)
                    .foregroundStyle(dayNumberColor)
                    .frame(width: 28, height: 28)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(Color.accentColor)
                        } else if isToday {
                            Circle()
                                .stroke(Color.accentColor, lineWidth: 1.5)
                        }
                    }

                VStack(spacing: 1) {
                    amountLabel(summary?.income, color: .income)
                    amountLabel(summary?.expense, color: .expense)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private var dayNumberColor: Color {
        if isSelected { return .white }
        if isToday { return .accentColor }
        return .primary
    }

    @ViewBuilder
    private func amountLabel(_ amount: Decimal?, color: Color) -> some View {
        if let amount, amount > 0 {
            Text(currencyString(amount, allowedDigits: 0))
                .font(.system(size: 9))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        } else {
            Spacer()
                .frame(height: 10)
        }
    }

    private var accessibilityLabel: String {
        var components = [DateFormatter.dayAccessibilityFormatter.string(from: date)]

        if isToday { components.append("今日") }
        if let income = summary?.income, income > 0 {
            components.append("収入 \(currencyString(income, allowedDigits: 0))")
        }
        if let expense = summary?.expense, expense > 0 {
            components.append("支出 \(currencyString(expense, allowedDigits: 0))")
        }

        return components.joined(separator: "、")
    }
}

extension DateFormatter {
    fileprivate static let dayAccessibilityFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M月d日"
        return formatter
    }()
}
