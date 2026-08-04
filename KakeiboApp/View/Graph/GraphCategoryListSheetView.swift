//
//  GraphCategoryListSheetView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/01
//
//

import SwiftUI

struct GraphCategoryListSheetView: View {
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel
    @ObservedObject var categoryListViewModel: CategoryListViewModel
    @Binding var isPresentCategoryList: Bool
    let selectedType: TransactionType

    var body: some View {
        NavigationStack {
            CategoryListView(
                categoryInputViewModel: categoryInputViewModel,
                categoryListViewModel: categoryListViewModel,
                isPresentCategoryList: $isPresentCategoryList,
                type: selectedType
            )
            .navigationTitle("カテゴリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        isPresentCategoryList = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
        .alert("エラー", isPresented: categoryListErrorAlertBinding) {
            Button("OK") { categoryListViewModel.clearError() }
        } message: {
            if let message = categoryListViewModel.errorMessage {
                Text(message)
            }
        }
        .overlay { categoryInputOverlay }
        .animation(.snappy, value: categoryInputViewModel.isPresentInputView)
    }

    private var categoryInputOverlay: some View {
        ZStack {
            if categoryInputViewModel.isPresentInputView {
                Color.black.opacity(0.4)
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
    }

    private var categoryListErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { categoryListViewModel.errorMessage != nil },
            set: { if !$0 { categoryListViewModel.clearError() } }
        )
    }
}
