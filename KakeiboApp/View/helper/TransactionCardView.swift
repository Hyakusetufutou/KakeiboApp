//
//  TransactionCardView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import SwiftUI

struct TransactionCardView: View {
    var transaction: TransactionModel
    var showsCategory: Bool = false
    var body: some View {
        SwipeAction(cornerRadius: 10) {
            HStack(spacing: 12) {
                Text("\(String(transaction.title.prefix(1)))")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                //                    .background(transaction.color.gradient, in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .foregroundStyle(Color.primary)

                    Text(transaction.memo)
                        .font(.caption)
                        .foregroundStyle(Color.primary)

                    Text(format(date: transaction.date, format: "dd MMM yyyy"))
                        .font(.caption2)
                        .foregroundStyle(.gray)

                    if showsCategory {
                        //                        Text(transaction.category)
                        //                            .font(.caption2)
                        //                            .padding(.horizontal, 5)
                        //                            .padding(.vertical, 2)
                        //                            .foregroundStyle(.white)
                        //                            .background(transaction.category == Category.income.rawValue ? Color.green.gradient : Color.red.gradient, in: .capsule)
                    }
                }
                .lineLimit(1)
                .hSpacing(.leading)

                Text(currencyString(transaction.amount, allowedDigits: 2))
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(.background, in: .rect(cornerRadius: 10))
        } onDelete: {
        }

    }
}

#Preview {
    ContentView()
}
