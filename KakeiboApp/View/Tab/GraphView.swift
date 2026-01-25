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

    @State private var pressed = false

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
            ScrollView(.vertical) {
                LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                    Section {
                        VStack {
                            ChangeMonthView(
                                date: $graphViewModel.startDate,
                                onPreviousMonth: {
                                    graphViewModel.changeMonth(by: -1)
                                },
                                onNextMonth: {
                                    graphViewModel.changeMonth(by: 1)
                                }
                            )

                            CustomSegmentedControl(selectedType: $graphViewModel.selectedType)
                                .hSpacing()

                            graphViewCategoryList()

                        }
                        .padding(.horizontal, 16)
                        .background(Color(.systemGroupedBackground))
                        .disabled(categoryInputViewModel.isPresentInputView)
                    } header: {
                        HStack {
                            Text("グラフ")
                                .font(.title2.bold())

                            Spacer()

                            Button {
                                isPresentCategoryList = true
                            } label: {
                                Image(systemName: "list.bullet")
                                    .font(.title2)
                                    .foregroundStyle(.black)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .background {
                                        Capsule()
                                            .fill(.white)
                                            .shadow(color: .gray.opacity(0.3), radius: 8, y: 1)
                                    }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(Color(.systemGroupedBackground))
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
        .animation(.snappy, value: graphViewModel.selectedType)
        .sheet(isPresented: $isPresentCategoryList) {
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
                ZStack {
                    if categoryInputViewModel.isPresentInputView {
                        Color.gray.opacity(0.5)
                            .ignoresSafeArea()
                    }

                    VStack {
                        Spacer()

                        if categoryInputViewModel.isPresentInputView {
                            CategoryInputView(
                                categoryInputViewModel: categoryInputViewModel
                            )
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            .animation(.snappy, value: categoryInputViewModel.isPresentInputView)
        }
    }

    @ViewBuilder
    func navigationTitle() -> some View {
        HStack {
            Text("グラフ")
                .font(.title.bold())
                .padding(.leading)
                .padding(.top, 16)
            Spacer()
        }
    }

    @ViewBuilder
    func graphViewCategoryList() -> some View {
        if !graphViewModel.categorySummaries.isEmpty {
            Text(
                "\(graphViewModel.totalTitle)  \(currencyString(graphViewModel.totalAmount, allowedDigits: 0))"
            )
            .font(.title3.bold())
            .padding(.vertical, 8)

            PieChartView(data: graphViewModel.categorySummaries)
                .frame(height: 200)

            VStack(spacing: 0) {
                ForEach(
                    graphViewModel.categorySummaries
                ) { summary in
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

                            Spacer()

                            Text(currencyString(summary.totalAmount, allowedDigits: 2))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(.systemBackground))
                    }
                    .buttonStyle(.plain)

                    if summary.id != graphViewModel.categorySummaries.last?.id {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .padding(.top, 8)
        } else {
            VStack {
                Text("取引なし")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Image(systemName: "xmark.seal.fill")
                    .font(.custom("", size: 100))
            }
            .padding(.top, 24)
        }
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
