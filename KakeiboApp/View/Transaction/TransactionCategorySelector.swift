//
//  TransactionCategorySelector.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/03
//
//

import SwiftUI

struct TransactionCategorySelector: View {
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("カテゴリ")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Menu {
                Button {
                    withAnimation(.snappy) {
                        categoryInputViewModel.presentInputView(
                            type: transactionInputViewModel.type
                        )
                    }
                } label: {
                    Label("カテゴリを追加", systemImage: "plus.circle.fill")
                }

                if !transactionInputViewModel.availableCategories.isEmpty {
                    ForEach(transactionInputViewModel.availableCategories) { item in
                        Button(item.name) {
                            transactionInputViewModel.selectedCategoryId = item.id
                        }
                    }
                }
            } label: {
                HStack {
                    Text(transactionInputViewModel.selectedCategory?.name ?? "選択してください")
                        .font(.callout)
                        .padding(.leading, 12)
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .padding(.trailing, 12)
                        .opacity(0.5)
                }
                .foregroundStyle(.primary)
                .frame(height: 44)
                .background(.background, in: .rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .tint(.primary)
        }
    }
}
