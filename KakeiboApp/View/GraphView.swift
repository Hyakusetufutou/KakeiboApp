//
//  GraphView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

struct GraphView: View {
    @Namespace private var animation
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
                    PieChartView(data: graphViewModel.categorySummaries)
                        .frame(height: 200)
                        .padding()
                } else {
                    Text("取引なし")
                        .frame(height: 200)
                        .padding()
                }

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
            }
            .padding(.horizontal, 15)
            .background(.gray.opacity(0.15))
            .disabled(categoryInputViewModel.isPresentInputView)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack {
                        Text("グラフ")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentCategoryList = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                }
            }
        }
        .sheet(isPresented: $isPresentCategoryList) {
            CategoryListView(
                categoryInputViewModel: categoryInputViewModel,
                isPresentCategoryList: $isPresentCategoryList,
                categories: $graphViewModel.categories,
                onDeleteCategory: { category in
                    graphViewModel.deleteCategory(category)
                }
            )
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
                            .transition(.move(edge: .bottom))
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
