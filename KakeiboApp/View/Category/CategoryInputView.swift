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
        VStack(spacing: 20) {
            headerView
            nameInputSection
            CategoryColorPickerView(selectedColor: $categoryInputViewModel.color)
            actionButtons
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 20, y: 10)
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

    private var headerView: some View {
        Text(categoryInputViewModel.isEdit ? "カテゴリを編集" : "カテゴリを追加")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .center)
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
                .submitLabel(.done)
                .focused($isFocused)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                isFocused = false
                categoryInputViewModel.cancel()
            } label: {
                Text("キャンセル")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(.secondary)

            Button {
                Task {
                    isFocused = false
                    await categoryInputViewModel.save()
                }
            } label: {
                Text(categoryInputViewModel.isEdit ? "更新" : "作成")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
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
