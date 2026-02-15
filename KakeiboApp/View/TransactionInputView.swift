//
//  TransactionInputView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/22
//
//

import SwiftUI

struct TransactionInputView: View {
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel

    @Namespace private var animation
    @FocusState private var isNumberPadActive: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 16) {
                    titleField
                    memoField
                    typeAndCategorySection
                    amountField
                    datePickerSection
                }
                .padding(16)
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
            .interactiveDismissDisabled(true)
            .alert("エラー", isPresented: errorAlertBinding) {
                Button("OK") {
                    transactionInputViewModel.clearError()
                }
            } message: {
                if let errorMessage = transactionInputViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
        .overlay {
            categoryInputOverlay
        }
    }

    // MARK: - Input Fields

    private var titleField: some View {
        customTextField(
            "タイトル",
            hint: "タイトル",
            value: $transactionInputViewModel.title
        )
    }

    private var memoField: some View {
        customTextField(
            "メモ",
            hint: "メモ",
            value: $transactionInputViewModel.memo
        )
    }

    private var amountField: some View {
        customTextField(
            "金額",
            hint: "金額",
            value: $transactionInputViewModel.amount,
            keyboardType: .numberPad
        )
    }

    // MARK: - Type and Category Section

    private var typeAndCategorySection: some View {
        HStack(alignment: .top, spacing: 12) {
            TransactionTypeSelector(
                transactionType: $transactionInputViewModel.type,
                onChange: { transactionInputViewModel.resetSelectedCategory() }
            )
            .frame(maxWidth: .infinity)

            categorySelector
                .frame(maxWidth: .infinity)
        }
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
            Button {
                withAnimation(.snappy) {
                    categoryInputViewModel.presentInputView(type: transactionInputViewModel.type)
                }
            } label: {
                Label("カテゴリを追加", systemImage: "plus.circle.fill")
            }

            if !transactionInputViewModel.availableCategories.isEmpty {
                ForEach(transactionInputViewModel.availableCategories) { item in
                    Button(item.name) {
                        transactionInputViewModel.selectedCategoryId = item.id
                    }
                }
            }
        }
    }

    private var categoryMenuLabel: some View {
        HStack {
            Text(transactionInputViewModel.selectedCategory?.name ?? "選択してください")
                .font(.callout)
                .padding(.leading, 12)
                .lineLimit(1)

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
        .frame(height: 44)
        .background(.background, in: .rect(cornerRadius: 10))
    }

    // MARK: - Date Picker Section

    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionHeader("日付")

            DatePicker(
                "日付",
                selection: $transactionInputViewModel.date,
                displayedComponents: [.date]
            )
            .datePickerStyle(.compact)
            .environment(\.locale, Locale(identifier: "ja_JP"))
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.background, in: .rect(cornerRadius: 10))
        }
    }

    // MARK: - Toolbar Buttons

    private var cancelButton: some View {
        Button {
            transactionInputViewModel.cancel()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .disabled(categoryInputViewModel.isPresentInputView)
    }

    private var saveButton: some View {
        Button {
            Task {
                await transactionInputViewModel.save()
            }
        } label: {
            Image(systemName: "checkmark")
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
        }
        .disabled(isSaveButtonDisabled)
        .opacity(transactionInputViewModel.isFormValid ? 1.0 : 0.2)
    }

    // MARK: - Overlay

    private var categoryInputOverlay: some View {
        ZStack {
            if categoryInputViewModel.isPresentInputView {
                Color.gray.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            VStack {
                Spacer()

                if categoryInputViewModel.isPresentInputView {
                    CategoryInputView(categoryInputViewModel: categoryInputViewModel)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .animation(.snappy, value: categoryInputViewModel.isPresentInputView)
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

    // MARK: - Computed Properties

    private var isSaveButtonDisabled: Bool {
        !transactionInputViewModel.isFormValid
            || categoryInputViewModel.isPresentInputView
            || transactionInputViewModel.isLoading
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { transactionInputViewModel.errorMessage != nil },
            set: { if !$0 { transactionInputViewModel.clearError() } }
        )
    }
}
