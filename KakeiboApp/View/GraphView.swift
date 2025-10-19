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
    @State private var startDate: Date = .now.startOfMonth
    @State private var endDate: Date = .now.endOfMonth
    @State private var selectedType: TransactionType = .expense
    @State private var categorySummaries: [CategorySummary] = []
    @State private var isPresentCategoryList: Bool = false
    @Binding var isPresentCategoryInputView: Bool

    @ObservedObject private var categoryViewModel: CategoryViewModel
    @ObservedObject private var categoryInputViewModel: CategoryInputViewModel

    init(
        categoryViewModel: CategoryViewModel,
        categoryInputViewModel: CategoryInputViewModel,
        isPresentCategoryInputView: Binding<Bool>
    ) {
        self.categoryViewModel = categoryViewModel
        self.categoryInputViewModel = categoryInputViewModel
        self._isPresentCategoryInputView = isPresentCategoryInputView
    }

    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Spacer()

                    customSegmentedControl()

                    Spacer()
                }

                if !categorySummaries.isEmpty {
                    PieChartView(data: categorySummaries)
                        .frame(height: 200)
                        .padding()
                } else {
                    Text("取引なし")
                        .frame(height: 200)
                        .padding()
                }

                ScrollView {
                    LazyVStack {
                        FilterTransactionsView(startDate: startDate, endDate: endDate) {
                            transactions in
                            ForEach(
                                transactions.filter({ transaction in
                                    transaction.type.rawValue == selectedType.rawValue
                                })
                            ) { transaction in
                                NavigationLink(value: transaction) {
                                    TransactionCardView(transaction: transaction)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .background(.gray.opacity(0.15))
            .disabled(isPresentCategoryInputView)
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
                if isPresentCategoryInputView {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                }

                VStack {
                    Spacer()

                    if isPresentCategoryInputView {
                        AddCategoryView(
                            categoryInputViewModel: categoryInputViewModel,
                            onClose: { isPresentCategoryInputView = false },
                            onCreate: {
                                isPresentCategoryInputView = false
                            }
                        )
                        .transition(.move(edge: .bottom))
                    }
                }
            }
        }
        .animation(.snappy, value: isPresentCategoryInputView)
        .onAppear {
            updateSummaries(for: selectedType)
        }
        .onChange(of: selectedType) { newValue in
            updateSummaries(for: newValue)
        }
        .sheet(isPresented: $isPresentCategoryList) {
            CategoryInputView(categoryInputViewModel: categoryInputViewModel)
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
    func customSegmentedControl() -> some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Text(type.rawValue)
                    .hSpacing()
                    .padding(.vertical, 10)
                    .background {
                        if type == selectedType {
                            Capsule()
                                .fill(.background)
                                .matchedGeometryEffect(id: "GRAPHTYPE", in: animation)
                        }
                    }
                    .contentShape(.capsule)
                    .onTapGesture {
                        withAnimation(.snappy) {
                            if selectedType != type {
                                selectedType = type
                            }
                        }
                    }
            }
        }
        .background(.gray.opacity(0.15), in: .capsule)
        .padding(.top, 5)
    }

    private func updateSummaries(for type: TransactionType) {
        categorySummaries = [.mock1, .mock2, .mock3].filter { $0.type == type }
    }
}

#Preview {
    @State var hoge = false
    GraphView(
        categoryViewModel: CategoryViewModel(repository: CategoryRepository()),
        categoryInputViewModel: CategoryInputViewModel(
            categoryViewModel: CategoryViewModel(repository: CategoryRepository())
        ),
        isPresentCategoryInputView: $hoge
    )
}
