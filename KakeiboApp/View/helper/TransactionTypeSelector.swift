//
//  TransactionTypeSelector.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/15
//
//

import SwiftUI

struct TransactionTypeSelector: View {
    @Binding var transactionType: TransactionType
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("種類")
                .font(.caption)
                .foregroundStyle(.gray)
                .hSpacing(.leading)

            HStack(spacing: 10) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    ZStack {
                        Text(type.rawValue)
                            .font(.callout)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background {
                                if transactionType == type {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.gray.opacity(0.15))
                                        .matchedGeometryEffect(
                                            id: "CATEGORYTYPE",
                                            in: animation
                                        )
                                }
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                            .onTapGesture {
                                withAnimation {
                                    transactionType = type
                                }
                            }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(8)
            .cornerRadius(40)
            .background {
                if colorScheme == .dark {
                    Color.black.cornerRadius(10)
                } else {
                    Color.white.cornerRadius(10)
                }
            }
        }
    }
}
