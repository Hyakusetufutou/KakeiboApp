//
//  CardView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import SwiftUI

struct CardView: View {
    var income: Decimal
    var expense: Decimal

    private var balance: Decimal { income - expense }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(.background)

            VStack(spacing: 0) {
                // 収支合計
                HStack(spacing: 12) {
                    Text(currencyString(balance))
                        .font(.title.bold())
                        .foregroundStyle(.primary)

                    Image(
                        systemName: balance >= 0
                            ? "chart.line.uptrend.xyaxis"
                            : "chart.line.downtrend.xyaxis"
                    )
                    .font(.title3)
                    .foregroundStyle(balance >= 0 ? Color.income : Color.expense)
                }
                .padding(.bottom, 25)

                // 収入・支出の内訳
                HStack(spacing: 0) {
                    ForEach(TransactionType.allCases, id: \.rawValue) { type in
                        HStack(spacing: 10) {
                            Image(systemName: type == .income ? "arrow.up" : "arrow.down")
                                .font(.callout.bold())
                                .foregroundStyle(tint(for: type))
                                .frame(width: 35, height: 35)
                                .background {
                                    Circle()
                                        .fill(tint(for: type).opacity(0.25).gradient)
                                }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.rawValue)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(currencyString(amount(for: type), allowedDigits: 0))
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)
                            }

                            if type == .income {
                                Spacer(minLength: 10)
                            }
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom], 25)
            .padding(.top, 15)
        }
    }

    // MARK: - Helpers

    private func tint(for type: TransactionType) -> Color {
        type == .income ? .income : .expense
    }

    private func amount(for type: TransactionType) -> Decimal {
        type == .income ? income : expense
    }
}

#Preview {
    ScrollView {
        CardView(income: 4590, expense: 2389)
    }
}
