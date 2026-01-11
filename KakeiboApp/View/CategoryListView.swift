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
    @Binding var isPresentCategoryList: Bool
    @Binding var categories: [CategoryModel]

    let onDeleteCategory: (CategoryModel) -> Void
    let type: TransactionType

    init(
        categoryInputViewModel: CategoryInputViewModel,
        isPresentCategoryList: Binding<Bool>,
        categories: Binding<[CategoryModel]>,
        onDeleteCategory: @escaping (CategoryModel) -> Void,
        type: TransactionType
    ) {
        self.categoryInputViewModel = categoryInputViewModel
        self._isPresentCategoryList = isPresentCategoryList
        self._categories = categories
        self.onDeleteCategory = onDeleteCategory
        self.type = type
    }

    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.snappy) {
                        categoryInputViewModel.presentInputView(type: type)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background {
                            Capsule()
                                .fill(.white)
                                .shadow(color: .gray.opacity(0.3), radius: 8, y: 1)
                        }
                }

                Spacer()

                Text("\(type.rawValue)カテゴリ")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    isPresentCategoryList = false
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .foregroundStyle(.primary)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background {
                            Capsule()
                                .fill(.white)
                                .shadow(color: .gray.opacity(0.3), radius: 8, y: 1)
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            List {
                ForEach(categories) { category in
                    HStack {
                        Circle()
                            .frame(width: 12)
                            .foregroundStyle(category.color)

                        Text(category.name)

                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        categoryInputViewModel.presentInputView(type: type, categoryItem: category)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            onDeleteCategory(category)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}
