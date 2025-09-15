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

    var balance: Double { income - expense }

    var body: some View {
        VStack(spacing: 12) {
            Text("今月の収支")
                .font(.headline)

            HStack {
                VStack {
                    Text("収入")
                    Text("\(Int(income))円")
                        .foregroundStyle(.green)
                }

                Spacer()

                VStack {
                    Text("支出")
                    Text("\(Int(expense))円")
                        .foregroundStyle(.red)
                }

                Spacer()

                VStack {
                    Text("残高")
                    Text("\(Int(balance))円")
                        .foregroundStyle(balance >= 0 ? .primary : Color.red)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemBackground)))
        .shadow(radius: 4)
        .padding(.horizontal)
    }
}

#Preview {
    ExpensesCardView(income: 1000, expense: 100)
}
