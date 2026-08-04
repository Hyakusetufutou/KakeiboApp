//
//  DaySummaryView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/05
//
//

import SwiftUI

struct DaySummaryView: View {
    let income: Decimal
    let expense: Decimal

    private var balance: Decimal { income - expense }

    var body: some View {
        HStack(spacing: 8) {
            summaryColumn(
                title: "収入",
                value: currencyString(income, allowedDigits: 0),
                color: .income
            )

            Spacer()

            summaryColumn(
                title: "支出",
                value: currencyString(expense, allowedDigits: 0),
                color: .expense
            )

            Spacer()

            summaryColumn(
                title: "合計",
                value: currencyString(balance, allowedDigits: 0),
                color: balance >= 0 ? .income : .expense
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func summaryColumn(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
    }
}

#Preview {
    DaySummaryView(income: 1000.0, expense: 500.0)
}
