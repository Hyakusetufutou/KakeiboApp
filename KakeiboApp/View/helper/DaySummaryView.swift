//
//  DaySummaryView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/05
//
//

import SwiftUI

struct DaySummaryView: View {
    let income: Double
    let expense: Double

    var balance: Double {
        income - expense
    }

    var body: some View {
        HStack(spacing: 8) {
            VStack {
                Text("収入")
                    .font(.caption)
                Text(currencyString(income, allowedDigits: 0))
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
            }

            Spacer()

            VStack {
                Text("支出")
                    .font(.caption)
                Text(currencyString(expense, allowedDigits: 0))
                    .fontWeight(.semibold)
                    .foregroundStyle(.red)
            }

            Spacer()

            VStack {
                Text("合計")
                    .font(.caption)
                Text(currencyString(balance, allowedDigits: 0))
                    .fontWeight(.semibold)
                    .foregroundStyle(balance >= 0 ? .green : .red)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    DaySummaryView(income: 1000.0, expense: 500.0)
}
