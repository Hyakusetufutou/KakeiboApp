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
    @State private var category: String = "なし"
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {

                VStack(alignment: .leading, spacing: 12) {
                    customTextField(
                        "タイトル",
                        hint: "タイトル",
                        value: $viewModel.title
                    )
                    customTextField(
                        "メモ",
                        hint: "メモ",
                        value: $viewModel.memo
                    )

                    HStack(alignment: .top, spacing: 15) {
                        TransactionTypeSelector(
                            transactionType: $viewModel.type,
                            onChange: { viewModel.resetSelectedCategory() }
                        )
                        categorySelector()
                    }
                    .frame(maxWidth: .infinity)

                    customTextField(
                        "金額",
                        hint: "金額",
                        value: $viewModel.amount,
                        keyboardType: .numberPad
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("日付")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .hSpacing(.leading)

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
            }
            .padding(15)
            .scrollIndicators(.hidden)
            .background(.gray.opacity(0.15))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("閉じる") {
                        isNumberPadActive = false
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.isPresentInputView = false
                    } label: {
                        Text("キャンセル")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.save()
                    } label: {
                        Text("保存")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                    .disabled(!viewModel.isValid())
                    .opacity(viewModel.isValid() ? 1.0 : 0.2)
                }
            }
        }
    }

    @ViewBuilder
    func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.gray)
            .hSpacing(.leading)
    }

    @ViewBuilder
    func customTextField(
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

    @ViewBuilder
    func categorySelector() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("カテゴリ")
            Menu {
                ForEach(
                    viewModel.availableCategories
                ) {
                    item in
                    Button(item.name) {
                        viewModel.selectedCategoryId = item.id
                    }
                }
            } label: {
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
        }
    }
}
