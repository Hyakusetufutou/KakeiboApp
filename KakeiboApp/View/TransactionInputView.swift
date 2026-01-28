//
//  TransactionInputView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/22
//
//

import SwiftUI

struct TransactionInputView: View {
    @ObservedObject var viewModel: TransactionInputViewModel

    @Namespace private var animation
    @FocusState private var isNumberPadActive
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 12) {
                    titleField
                    memoField
                    typeAndCategorySection
                    amountField
                    datePickerSection
                }
                .padding(15)
            }
            .scrollIndicators(.hidden)
            .background(.gray.opacity(0.15))
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .topBarTrailing) {
                    saveButton
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {}
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Input Fields

    private var titleField: some View {
        customTextField(
            "タイトル",
            hint: "タイトル",
            value: $viewModel.title
        )
    }

    private var memoField: some View {
        customTextField(
            "メモ",
            hint: "メモ",
            value: $viewModel.memo
        )
    }

    private var amountField: some View {
        customTextField(
            "金額",
            hint: "金額",
            value: $viewModel.amount,
            keyboardType: .numberPad
        )
    }

    // MARK: - Type and Category Section

    private var typeAndCategorySection: some View {
        HStack(alignment: .top, spacing: 15) {
            TransactionTypeSelector(
                transactionType: $viewModel.type,
                onChange: { viewModel.resetSelectedCategory() }
            )
            categorySelector
        }
        .frame(maxWidth: .infinity)
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("カテゴリ")

            Menu {
                categoryMenuContent
            } label: {
                categoryMenuLabel
            }
        }
    }

    private var categoryMenuContent: some View {
        Group {
            if viewModel.availableCategories.isEmpty {
                Text("カテゴリなし")
            } else {
                ForEach(viewModel.availableCategories) { item in
                    Button(item.name) {
                        viewModel.selectedCategoryId = item.id
                    }
                }
            }
        }
    }

    private var categoryMenuLabel: some View {
        HStack {
            Text(viewModel.selectedCategory?.name ?? "選択してください")
                .font(.callout)
                .padding(.leading, 12)

            Spacer()

            VStack(spacing: 2) {
                Image(systemName: "arrowtriangle.up.fill")
                Image(systemName: "arrowtriangle.down.fill")
            }
            .font(.system(size: 8))
            .padding(.trailing, 12)
            .opacity(0.5)
        }
        .foregroundStyle(colorScheme == .dark ? .white : .black)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background, in: .rect(cornerRadius: 10))
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("日付")

            HStack {
                Spacer()

                DatePicker(
                    "日付",
                    selection: $viewModel.date,
                    displayedComponents: [.date]
                )
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .datePickerStyle(.graphical)
                .clipped()
                .frame(maxWidth: .infinity)

                Spacer()
            }
            .background(.background, in: .rect(cornerRadius: 10))
        }
    }

    // MARK: - Toolbar Buttons

    private var cancelButton: some View {
        Button {
            viewModel.cancel()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
            //                .background(
            //                    Circle()
            //                        .fill(Color(.systemBackground))
            //                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            //                )
        }
        //        .buttonStyle(.borderless)
    }

    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save()
            }
        } label: {
            Image(systemName: "checkmark")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
            //                .background(
            //                    Circle()
            //                        .fill(Color(.systemBackground))
            //                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
            //                )
        }
        //        .buttonStyle(.borderless)
        .disabled(!viewModel.isValid())
        .opacity(viewModel.isValid() ? 1.0 : 0.2)
    }

    // MARK: - Helper Views

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.gray)
            .hSpacing(.leading)
    }

    private func customTextField(
        _ title: String,
        hint: String,
        value: Binding<String>,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader(title)

            TextField(hint, text: value)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(.background, in: .rect(cornerRadius: 10))
                .keyboardType(keyboardType)
                .focused($isNumberPadActive)
        }
    }
}
