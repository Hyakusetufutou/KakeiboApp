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
                Text("\(category?.name.prefix(1) ?? "")")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(width: 45, height: 45)
                    .background((category?.color ?? .blue).gradient, in: .circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text(transaction.title)
                        .foregroundStyle(Color.primary)

                    Text(transaction.memo)
                        .font(.caption)
                        .foregroundStyle(Color.primary)

                    HStack {
                        Text(format(date: transaction.date, format: "yyyy/MM/dd"))
                            .font(.caption2)
                            .foregroundStyle(.gray)

                        if let category = category {
                            Text(category.name)
                                .font(.caption2)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .foregroundStyle(.white)
                                .background(
                                    category.color.gradient,
                                    in: .capsule
                                )
                        }
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
            onDelete(transaction)
        }

    }
}

#Preview {
    ContentView()
        .environmentObject(ViewModelFactory())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
