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
        HStack {
            Circle()
                .frame(width: 12)
                .foregroundStyle(category.color.color)

            Text(category.name)

            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            categoryInputViewModel.presentInputView(type: type, categoryItem: category)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                Task { await categoryListViewModel.delete(category) }
            } label: {
                Image(systemName: "trash")
            }
            .tint(.red)
        }
    }
}
