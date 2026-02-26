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
    var category: CategoryModel?
    var onDelete: (TransactionModel) -> Void

    var body: some View {
        SwipeAction(cornerRadius: 10) {
            HStack(spacing: 12) {
                categoryIcon
                transactionInfo
                Spacer()
                amountText
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            .background(cardBackground)
        } onDelete: {
            onDelete(transaction)
        }
    }

    // MARK: - Components

    private var categoryIcon: some View {
        Text(category?.name.prefix(1).description ?? "?")
            .font(.title)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .frame(width: 45, height: 45)
            .background((category?.color ?? .blue).gradient, in: .circle)
    }

    private var transactionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(transaction.title)
                .foregroundStyle(.primary)
                .lineLimit(1)

            if !transaction.memo.isEmpty {
                Text(transaction.memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                Text(format(date: transaction.date, format: "yyyy/MM/dd"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                if let category {
                    Text(category.name)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .foregroundStyle(.white)
                        .background(category.color.gradient, in: .capsule)
                }
            }
        }
    }

    private var amountText: some View {
        Text(currencyString(transaction.amount, allowedDigits: 0))
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundStyle(transaction.type == .income ? Color.income : Color.expense)
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: Color(.label).opacity(0.06), radius: 2, y: 1)
    }
}

#Preview("Light Mode") {
    VStack(spacing: 8) {
        TransactionCardView(transaction: .mock1, category: .mock1, onDelete: { _ in })
        TransactionCardView(transaction: .mock2, category: .mock2, onDelete: { _ in })
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    VStack(spacing: 8) {
        TransactionCardView(transaction: .mock1, category: .mock1, onDelete: { _ in })
        TransactionCardView(transaction: .mock2, category: .mock2, onDelete: { _ in })
    }
    .padding()
    .background(Color(.systemGroupedBackground))
    .preferredColorScheme(.dark)
}
