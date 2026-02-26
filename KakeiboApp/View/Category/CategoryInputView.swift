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
            headerView
            nameInputSection
            colorPickerSection
            actionButtons
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color(.label).opacity(0.10), radius: 20, y: 10)
        )
        .padding(.horizontal, 24)
        .alert("エラー", isPresented: errorAlertBinding) {
            Button("OK") {
                categoryInputViewModel.clearError()
            }
        } message: {
            if let errorMessage = categoryInputViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Components

    private var headerView: some View {
        Text(categoryInputViewModel.isEdit ? "カテゴリを編集" : "カテゴリを追加")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("名前")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("食費", text: $categoryInputViewModel.name)
                .padding(.vertical, 12)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .focused($isFocused)
        }
    }

    private var colorPickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("カラー")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                spacing: 12
            ) {
                ForEach(AppTheme.categoryColors, id: \.self) { color in
                    colorButton(color: color)
                }
            }
        }
    }

    private func colorButton(color: Color) -> some View {
        Circle()
            .fill(color)
            .frame(width: 34, height: 34)
            .overlay {
                if color == categoryInputViewModel.color {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
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

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // キャンセル
            Button {
                isFocused = false
                categoryInputViewModel.cancel()
            } label: {
                Text("キャンセル")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    .foregroundStyle(.primary)
            }

            // 保存・更新
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
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.accentColor)
                    )
                    .foregroundStyle(.white)
                    .opacity(categoryInputViewModel.name.isEmpty ? 0.5 : 1)
            }
            .disabled(categoryInputViewModel.name.isEmpty)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { categoryInputViewModel.errorMessage != nil },
            set: { if !$0 { categoryInputViewModel.clearError() } }
        )
    }
}

#Preview("Light Mode") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        CategoryInputView(
            categoryInputViewModel: CategoryInputViewModel(
                categoryStore: CategoryStore(repository: CategoryRepository())
            )
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        Color(.systemGroupedBackground).ignoresSafeArea()
        CategoryInputView(
            categoryInputViewModel: CategoryInputViewModel(
                categoryStore: CategoryStore(repository: CategoryRepository())
            )
        )
    }
    .preferredColorScheme(.dark)
}
