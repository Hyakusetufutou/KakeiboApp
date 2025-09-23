//
//  TransactionInputView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/22
//
//

import SwiftUI

struct TransactionInputView: View {
    @State private var title = ""
    @State private var memo = ""
    @State private var amount = ""
    @State private var date = Date()
    @Binding var isPresented: Bool

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
                        value: $title
                    )
                    customTextField(
                        "メモ",
                        hint: "メモ",
                        value: $memo
                    )

                    HStack(alignment: .top, spacing: 15) {
                        transactionTypeSelector()
                        categorySelector()
                    }
                    .frame(maxWidth: .infinity)

                    customTextField(
                        "金額",
                        hint: "金額",
                        value: $amount,
                        keyboardType: .numberPad
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("日付")
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .hSpacing(.leading)

                        DatePicker(
                            "日付",
                            selection: $date,
                            displayedComponents: [.date]
                        )
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                        .datePickerStyle(.graphical)
                        .background(.clear)
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
                        isPresented = false
                    } label: {
                        Text("キャンセル")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        //@@@ 保存処理実装時に対応
                    } label: {
                        Text("保存")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }
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
                //                ForEach(inputViewModel.availableCategories, id: \.id) { item in
                //                    Button(item.name) {
                //                        inputViewModel.selectedCategoryID = item.id
                //                    }
                //                }
            } label: {
                HStack {
                    Text("選択してください")
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

    @ViewBuilder
    func transactionTypeSelector() -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("種類")
                .font(.caption)
                .foregroundStyle(.gray)
                .hSpacing(.leading)

            HStack(spacing: 10) {
                ForEach(TransactionType.allCases, id: \.self) { type in
                    ZStack {
                        Text(type.rawValue)
                            .font(.callout)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background {
                                if type == type {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.gray.opacity(0.15))
                                        .matchedGeometryEffect(id: "TYPE", in: animation)
                                }
                            }
                            .contentShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(8)
            .cornerRadius(40)
            .background {
                if colorScheme == .dark {
                    Color.black.cornerRadius(10)
                } else {
                    Color.white.cornerRadius(10)
                }
            }
        }
    }
}
