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
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 16) {

            // MARK: - Header
            Text(categoryInputViewModel.isEdit ? "カテゴリを編集" : "カテゴリを追加")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: - Name Input
            VStack(alignment: .leading, spacing: 6) {
                Text("名前")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("食事", text: $categoryInputViewModel.name)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.thinMaterial)
                    )
                    .focused($isFocused)
            }

            // MARK: - Color Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("カラー")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                    spacing: 12
                ) {
                    ForEach(AppTheme.categoryColors, id: \.self) { color in
                        Circle()
                            .fill(color)
                            .frame(width: 34, height: 34)
                            .overlay {
                                if color == categoryInputViewModel.color {
                                    Circle()
                                        .stroke(color.opacity(0.8), lineWidth: 4)
                                        .shadow(color: color.opacity(0.4), radius: 6)
                                }
                            }
                            .scaleEffect(color == categoryInputViewModel.color ? 1.15 : 1)
                            .animation(
                                .spring(response: 0.35, dampingFraction: 0.7),
                                value: categoryInputViewModel.color
                            )
                            .onTapGesture {
                                categoryInputViewModel.color = color
                            }
                    }
                }
            }

            // MARK: - Actions
            HStack(spacing: 12) {
                Button {
                    isFocused = false
                    categoryInputViewModel.cancel()
                } label: {
                    Text("キャンセル")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.gray.opacity(0.6))
                        )
                        .foregroundStyle(.black)
                }

                Button {
                    Task {
                        isFocused = false
                        await categoryInputViewModel.save()
                    }
                } label: {
                    Text(categoryInputViewModel.isEdit ? "更新" : "作成")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    categoryInputViewModel.name.isEmpty
                                        ? .blue.opacity(0.2) : .blue
                                )
                        )
                        .foregroundStyle(.white)
                }
                .disabled(categoryInputViewModel.name.isEmpty)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
        .padding(.horizontal, 24)
        .alert("エラー", isPresented: .constant(categoryInputViewModel.errorMessage != nil)) {
            Button("OK") {}
        } message: {
            if let errorMessage = categoryInputViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}
