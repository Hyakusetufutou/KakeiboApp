//
//  CategoryListView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/24
//
//

import SwiftUI

struct CategoryListView: View {
    @ObservedObject var categoryViewModel: CategoryViewModel
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel
    @Binding var isPresentCategoryList: Bool

    init(
        categoryViewModel: CategoryViewModel,
        categoryInputViewModel: CategoryInputViewModel,
        isPresentCategoryList: Binding<Bool>
    ) {
        self.categoryViewModel = categoryViewModel
        self.categoryInputViewModel = categoryInputViewModel
        self._isPresentCategoryList = isPresentCategoryList
    }

    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.snappy) {
                        categoryInputViewModel.isPresentInputView = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .background {
                            Circle()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.black)
                        }
                }

                Spacer()

                Text("カテゴリリスト")
                    .font(.title3)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    isPresentCategoryList = false
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title2)
                        .background {
                            Circle()
                                .frame(width: 50, height: 50)
                                .foregroundStyle(.black)
                        }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            List {
                ForEach(categoryViewModel.categories) { category in
                    HStack {
                        Text(category.name)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        categoryInputViewModel.presentInputView(category)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            categoryViewModel.delete(category)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .tint(.red)
                    }
                }
            }
        }
    }
}
