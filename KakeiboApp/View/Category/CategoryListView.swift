//
//  CategoryListView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/24
//
//

import SwiftUI

struct CategoryListView: View {
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel
    @ObservedObject var categoryListViewModel: CategoryListViewModel
    @Binding var isPresentCategoryList: Bool

    let type: TransactionType

    var body: some View {
        VStack {
            headerView
            categoryList
        }
        .background(Color(.systemGroupedBackground))
    }

    private var headerView: some View {
        HStack {
            headerButton(icon: "plus") {
                withAnimation(.snappy) {
                    categoryInputViewModel.presentInputView(type: type)
                }
            }

            Spacer()

            Text("\(type.rawValue)カテゴリ")
                .font(.title3)
                .fontWeight(.bold)

            Spacer()

            headerButton(icon: "checkmark") {
                isPresentCategoryList = false
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private func headerButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background {
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color(.label).opacity(0.12), radius: 8, y: 1)
                }
        }
    }

    private var categoryList: some View {
        let categories = categoryListViewModel.categories.filter { $0.type == type }

        return List {
            ForEach(categories) { category in
                CategoryRowView(
                    category: category,
                    type: type,
                    categoryInputViewModel: categoryInputViewModel,
                    categoryListViewModel: categoryListViewModel
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
}
