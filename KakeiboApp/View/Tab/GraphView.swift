//
//  GraphView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

struct GraphView: View {
    @State private var isPresentCategoryList: Bool = false

    @ObservedObject private var graphViewModel: GraphViewModel
    @ObservedObject private var transactionInputViewModel: TransactionInputViewModel
    @ObservedObject private var categoryInputViewModel: CategoryInputViewModel

    init(
        graphViewModel: GraphViewModel,
        transactionInputViewModel: TransactionInputViewModel,
        categoryInputViewModel: CategoryInputViewModel
    ) {
        self.graphViewModel = graphViewModel
        self.transactionInputViewModel = transactionInputViewModel
        self.categoryInputViewModel = categoryInputViewModel
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
                            categorySection
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
        }
        .animation(.snappy, value: graphViewModel.selectedType)
        .disabled(categoryInputViewModel.isPresentInputView)
        .sheet(isPresented: $isPresentCategoryList) {
            categoryListSheet
        }
        .alert("エラー", isPresented: errorAlertBinding) {
            Button("OK") {
                graphViewModel.clearError()
            }
        } message: {
            if let errorMessage = graphViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Control Section

    private var controlSection: some View {
        Section {
            VStack(spacing: 12) {
                ChangeMonthView(
                    date: graphViewModel.startDate,
                    onPreviousMonth: { graphViewModel.changeMonth(by: -1) },
                    onNextMonth: { graphViewModel.changeMonth(by: 1) }
                )

                CustomSegmentedControl(selectedType: $graphViewModel.selectedType)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        } header: {
            headerView
        }
    }

    private var headerView: some View {
        HStack {
            Text("グラフ")
                .font(.title2.bold())

            Spacer()

            ActionButton(imageName: "list.bullet") {
                isPresentCategoryList = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Category Section

    private var categorySection: some View {
        Section {
            VStack(spacing: 12) {
                totalAmountView
                pieChartView
                categoryListView
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
    }

    private var totalAmountView: some View {
        Text(
            "\(graphViewModel.totalTitle)  \(currencyString(graphViewModel.totalAmount, allowedDigits: 0))"
        )
        .font(.title3.bold())
    }

    private var pieChartView: some View {
        PieChartView(data: graphViewModel.categorySummaries)
            .frame(height: 200)
    }

    private var categoryListView: some View {
        VStack(spacing: 0) {
            ForEach(graphViewModel.categorySummaries) { summary in
                categoryRow(summary: summary)

                if summary.id != graphViewModel.categorySummaries.last?.id {
                    Divider()
                        .padding(.leading, 44)
                }
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func categoryRow(summary: CategorySummary) -> some View {
        NavigationLink(
            destination: TransactionListByCategory(
                graphViewModel: graphViewModel,
                transactionInputViewModel: transactionInputViewModel,
                categoryID: summary.categoryID,
                onDeleteTransaction: { transaction in
                    Task {
                        await graphViewModel.deleteTransaction(transaction)
                    }
                }
            )
        ) {
            HStack {
                Circle()
                    .frame(width: 12)
                    .foregroundStyle(summary.color)

                Text(summary.categoryName)
                    .foregroundStyle(.primary)

                Spacer()

                Text(currencyString(summary.totalAmount, allowedDigits: 2))
                    .foregroundStyle(.primary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(.systemBackground))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty Section

    private var emptySection: some View {
        Section {
            NoTransactionView()
                .padding(.horizontal, 16)
                .padding(.top, 4)
        }
    }

    // MARK: - Sheet

    private var categoryListSheet: some View {
        CategoryListView(
            categoryInputViewModel: categoryInputViewModel,
            isPresentCategoryList: $isPresentCategoryList,
            categories: $graphViewModel.categories,
            onDeleteCategory: { category in
                Task {
                    await graphViewModel.deleteCategory(category)
                }
            },
            type: graphViewModel.selectedType
        )
        .interactiveDismissDisabled(true)
        .overlay {
            categoryInputOverlay
        }
        .animation(.snappy, value: categoryInputViewModel.isPresentInputView)
    }

    private var categoryInputOverlay: some View {
        ZStack {
            if categoryInputViewModel.isPresentInputView {
                Color.black.opacity(0.3)
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

    // MARK: - Helper

    private var errorAlertBinding: Binding<Bool> {
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
        categoryInputViewModel: viewModelFactory.categoryInputViewModel
    )
}
