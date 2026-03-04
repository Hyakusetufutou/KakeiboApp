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

    // MARK: - Body

    var body: some View {
        VStack {
            headerView
            categoryList
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Header

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

    // MARK: - Category List

    private var categoryList: some View {
        let categories = categoryListViewModel.categories.filter { $0.type == type }

        return List {
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
                        Task { await categoryListViewModel.delete(category) }
                    } label: {
                        Image(systemName: "trash")
                    }
                    .tint(.red)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }
}
