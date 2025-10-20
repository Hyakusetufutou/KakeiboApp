//
//  CategoryInputView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/29
//
//

import SwiftUI

struct CategoryInputView: View {
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel
    @Namespace private var animation
    @Environment(\.colorScheme) var colorScheme

    var onClose: () -> Void
    var onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("カテゴリ名")
                .font(.caption)

            TextField("食事", text: $categoryInputViewModel.name)
                .padding(.horizontal, 10)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                }

            TransactionTypeSelector(transactionType: $categoryInputViewModel.type)

            Text("色")
                .font(.caption)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 6),
                spacing: 10
            ) {
                ForEach(AppTheme.categoryColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            if color == categoryInputViewModel.color {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 3)
                            }
                        }
                        .onTapGesture {
                            categoryInputViewModel.color = color
                        }
                }
            }
            .padding(.vertical, 5)

            HStack {
                Button {
                    onCreate()
                    categoryInputViewModel.add()
                } label: {
                    Text("作成")
                        .font(.title3)
                        .foregroundStyle(.backgroundLight)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.purple)
                                .opacity(categoryInputViewModel.name.isEmpty ? 0.2 : 1)
                        }
                }
                .disabled(categoryInputViewModel.name.isEmpty)

                Button {
                    onClose()
                } label: {
                    Text("中止")
                        .font(.title3)
                        .foregroundStyle(.backgroundLight)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.red)
                        }
                }
            }
        }
        .padding(15)
        .background(.bar, in: .rect(cornerRadius: 10))
        .padding(.horizontal, 30)
    }
}

#Preview {
    CategoryInputView(
        categoryInputViewModel: CategoryInputViewModel(
            categoryViewModel: CategoryViewModel(repository: CategoryRepository())
        ),
        onClose: {},
        onCreate: {}
    )
}
