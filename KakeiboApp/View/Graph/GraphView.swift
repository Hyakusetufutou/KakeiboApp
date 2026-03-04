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
        .disabled(categoryInputViewModel.isPresentInputView)
        .sheet(isPresented: $isPresentCategoryList) {
            categoryListSheet
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
                    date: graphViewModel.startDate,
                    onPreviousMonth: { graphViewModel.changeMonth(by: -1) },
                    onNextMonth: { graphViewModel.changeMonth(by: 1) }
                )

                CustomSegmentedControl(selectedType: $graphViewModel.selectedType)
                    .animation(.snappy, value: graphViewModel.selectedType)
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
            .animation(.snappy, value: graphViewModel.categorySummaries.map(\.id))
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
        let summaries = graphViewModel.categorySummaries

        return VStack(spacing: 0) {
            ForEach(summaries.indices, id: \.self) { index in
                categoryRow(summary: summaries[index])

                if index < summaries.count - 1 {
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
                    Task { await graphViewModel.deleteTransaction(transaction) }
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
            .contentShape(Rectangle())
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
            categoryListViewModel: categoryListViewModel,
            isPresentCategoryList: $isPresentCategoryList,
            type: graphViewModel.selectedType
        )
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
                Color(.label).opacity(0.4)
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

    // MARK: - Helpers

    private var graphErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { graphViewModel.errorMessage != nil },
            set: { if !$0 { graphViewModel.clearError() } }
        )
    }

    private var categoryListErrorAlertBinding: Binding<Bool> {
        Binding(
            get: { categoryListViewModel.errorMessage != nil },
            set: { if !$0 { categoryListViewModel.clearError() } }
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
