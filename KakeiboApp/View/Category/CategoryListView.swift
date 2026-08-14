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
        categoryList
            .navigationTitle("\(type.rawValue)カテゴリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.snappy) {
                            categoryInputViewModel.presentInputView(type: type)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("カテゴリを追加")
                }
            }
    }

    private var categoryList: some View {
        let categories = categoryListViewModel.categories.filter { $0.type == type }

        return Group {
            if categories.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(icon: "tag", message: "カテゴリがありません")
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .background(AppTheme.background)
            } else {
                List {
                    ForEach(categories) { category in
                        CategoryRowView(
                            category: category,
                            type: type,
                            categoryInputViewModel: categoryInputViewModel,
                            categoryListViewModel: categoryListViewModel
                        )
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}
