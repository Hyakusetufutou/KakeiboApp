//
//  ExpenseCardView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/08
//
//

import SwiftUI

struct ExpensesCardView: View {
    let income: Double
    let expense: Double

    private var balance: Double { income - expense }

    var body: some View {
        VStack(spacing: 12) {
            Text("今月の収支")
                .font(.headline)

            HStack {
                VStack(spacing: 4) {
                    Text("収入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currencyString(income, allowedDigits: 0))
                        .foregroundStyle(Color.income)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("支出")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currencyString(expense, allowedDigits: 0))
                        .foregroundStyle(Color.expense)
                }

                Spacer()

                VStack(spacing: 4) {
                    Text("残高")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(currencyString(balance, allowedDigits: 0))
                        .foregroundStyle(balance >= 0 ? Color.income : Color.expense)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.label).opacity(0.08), radius: 4, y: 2)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ExpensesCardView(income: 1000, expense: 100)
}
