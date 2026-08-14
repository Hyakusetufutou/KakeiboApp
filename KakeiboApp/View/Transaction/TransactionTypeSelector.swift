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
    var onChange: () -> Void
    @Namespace private var animation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("種類")
                .font(.caption)
                .foregroundStyle(.secondary)
                .hSpacing(.leading)

            HStack(spacing: 10) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    Text(type.rawValue)
                        .font(.callout)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity)
                        .background {
                            if transactionType == type {
                                if #available(iOS 26.0, *) {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.segmentBackground)
                                        .matchedGeometryEffect(id: "CATEGORYTYPE", in: animation)
                                } else {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(AppTheme.segmentBackground)
                                        .matchedGeometryEffect(id: "CATEGORYTYPE", in: animation)
                                }
                            }
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                        .onTapGesture {
                            withAnimation(.snappy) {
                                transactionType = type
                                onChange()
                            }
                        }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.cardBackground)
            )
        }
    }
}
