//
//  GraphView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

struct GraphView: View {
    @State private var isPresentCategoryList = false

    @ObservedObject private var graphViewModel: GraphViewModel
    @ObservedObject private var transactionInputViewModel: TransactionInputViewModel
    @ObservedObject private var categoryInputViewModel: CategoryInputViewModel
    @ObservedObject private var categoryListViewModel: CategoryListViewModel

    init(
        graphViewModel: GraphViewModel,
        transactionInputViewModel: TransactionInputViewModel,
        categoryInputViewModel: CategoryInputViewModel,
        categoryListViewModel: CategoryListViewModel
    ) {
        self.graphViewModel = graphViewModel
        self.transactionInputViewModel = transactionInputViewModel
        self.categoryInputViewModel = categoryInputViewModel
        self.categoryListViewModel = categoryListViewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: [.sectionHeaders]) {
                        controlSection

                        if !graphViewModel.categorySummaries.isEmpty {
                            GraphCategorySectionView(graphViewModel: graphViewModel)
                        } else {
                            emptySection
                        }
                    }
                }
                .refreshable {
                    await graphViewModel.reload()
                }

                if graphViewModel.isLoading && graphViewModel.categorySummaries.isEmpty {
                    ProgressView("読み込み中...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("グラフ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isPresentCategoryList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("カテゴリ一覧")
                }
            }
            .navigationDestination(for: UUID.self) { categoryID in
                TransactionListByCategory(
                    graphViewModel: graphViewModel,
                    transactionInputViewModel: transactionInputViewModel,
                    categoryID: categoryID,
                    onDeleteTransaction: { transaction in
                        graphViewModel.deleteTransaction(transaction)
                    }
                )
            }
        }
        .disabled(categoryInputViewModel.isPresentInputView)
        .sheet(isPresented: $isPresentCategoryList) {
            GraphCategoryListSheetView(
                categoryInputViewModel: categoryInputViewModel,
                categoryListViewModel: categoryListViewModel,
                isPresentCategoryList: $isPresentCategoryList,
                selectedType: graphViewModel.selectedType
            )
        }
        .alert("エラー", isPresented: graphErrorAlertBinding) {
            Button("OK") { graphViewModel.clearError() }
        } message: {
            if let message = graphViewModel.errorMessage {
                Text(message)
            }
        }
    }

    // MARK: - Control Section

    private var controlSection: some View {
        Section {
            VStack(spacing: 12) {
                ChangeMonthView(
                    date: $graphViewModel.dateRange.start,
                    onPreviousMonth: { graphViewModel.changeMonth(by: -1) },
                    onNextMonth: { graphViewModel.changeMonth(by: 1) }
                )

                CustomSegmentedControl(selectedType: $graphViewModel.selectedType)
                    .animation(.snappy, value: graphViewModel.selectedType)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        } header: {
            Color(.systemGroupedBackground)
                .frame(height: 0)
        }
    }

    private var emptySection: some View {
        Section {
            NoTransactionView()
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
    }

    private var graphErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { graphViewModel.errorMessage != nil },
            set: { if !$0 { graphViewModel.clearError() } }
        )
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()
    GraphView(
        graphViewModel: viewModelFactory.graphViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel,
        categoryInputViewModel: viewModelFactory.categoryInputViewModel,
        categoryListViewModel: viewModelFactory.categoryListViewModel
    )
}
