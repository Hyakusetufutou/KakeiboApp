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

                ScrollView {
                    LazyVStack {
                        ForEach(
                            graphViewModel.filteredTransactions
                        ) { transaction in
                            NavigationLink(value: transaction) {
                                TransactionCardView(
                                    transaction: transaction,
                                    category: graphViewModel.categoryViewModel.find(
                                        id: transaction.categoryId
                                    ),
                                    onDelete: { transaction in
                                        graphViewModel.transactionViewModel.delete(transaction)
                                    }
                                )
                                .onTapGesture {
                                    transactionInputViewModel.presentInputView(transaction)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(15)
            .background(.gray.opacity(0.15))
            .disabled(categoryInputViewModel.isPresentInputView)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("グラフ")
                        .font(.title.bold())
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        Button {
                            isPresentCategoryList = true
                        } label: {
                            Image(systemName: "list.bullet")
                        }

                        Button {

                        } label: {
                            Image(systemName: "calendar")
                        }
                    }
                }
            }
        }
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
                            categoryInputViewModel: categoryInputViewModel,
                            onClose: { categoryInputViewModel.isPresentInputView = false },
                            onCreate: {
                                categoryInputViewModel.isPresentInputView = false
                            }
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .animation(.snappy, value: categoryInputViewModel.isPresentInputView)
        .sheet(isPresented: $isPresentCategoryList) {
            CategoryListView(categoryViewModel: graphViewModel.categoryViewModel)
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
