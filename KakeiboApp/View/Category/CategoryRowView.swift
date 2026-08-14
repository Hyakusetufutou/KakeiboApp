//
//  CategoryRowView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/03
//
//

import SwiftUI

struct CategoryRowView: View {
    let category: CategoryModel
    let type: TransactionType
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel
    @ObservedObject var categoryListViewModel: CategoryListViewModel

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(category.color.color)
                .frame(width: 12, height: 12)

            Text(category.name)
                .foregroundStyle(.primary)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            categoryInputViewModel.presentInputView(type: type, categoryItem: category)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !category.isDefault {
                Button(role: .destructive) {
                    categoryListViewModel.delete(category)
                } label: {
                    Label("", systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("タップして編集")
    }
}
