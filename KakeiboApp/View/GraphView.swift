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

                HStack {
                    Spacer()

                    CustomSegmentedControl(selectedType: $graphViewModel.selectedType)

                    Spacer()
                }

                if !graphViewModel.categorySummaries.isEmpty {
                    Text(
                        "\(graphViewModel.totalTitle)  \(currencyString(graphViewModel.totalAmount, allowedDigits: 0))"
                    )
                    .font(.title3.bold())
                    .padding(.vertical, 8)

                    PieChartView(data: graphViewModel.categorySummaries)
                        .frame(height: 200)

                    List {
                        ForEach(
                            graphViewModel.categorySummaries
                        ) { summary in
                            NavigationLink(
                                destination: TransactionListByCategory(
                                    transactionInputViewModel: transactionInputViewModel,
                                    categorySummary: summary,
                                    onDeleteTransaction: { transaction in
                                        graphViewModel.deleteTransaction(transaction)
                                    },
                                    onFindCategory: { id in
                                        graphViewModel.findCategory(id: id)
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
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .scrollContentBackground(.hidden)
                } else {
                    Text("取引なし")
                        .frame(maxHeight: .infinity)
                        .padding()
                }

            }
            .padding(.horizontal, 15)
            .background(Color(.systemGroupedBackground))
            .disabled(categoryInputViewModel.isPresentInputView)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentCategoryList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
            .navigationTitle("グラフ")
            .navigationBarTitleDisplayMode(.inline)
        }
        .animation(.snappy, value: graphViewModel.selectedType)
        .sheet(isPresented: $isPresentCategoryList) {
            CategoryListView(
                categoryInputViewModel: categoryInputViewModel,
                isPresentCategoryList: $isPresentCategoryList,
                categories: $graphViewModel.categories,
                onDeleteCategory: { category in
                    graphViewModel.deleteCategory(category)
                },
                type: graphViewModel.selectedType
            )
            .interactiveDismissDisabled(true)
            .overlay {
                ZStack {
                    if categoryInputViewModel.isPresentInputView {
                        Color.black.opacity(0.5)
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
}

#Preview {
    let viewModelFactory = ViewModelFactory()
    GraphView(
        graphViewModel: viewModelFactory.graphViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel,
        categoryInputViewModel: viewModelFactory.categoryInputViewModel
    )
}
