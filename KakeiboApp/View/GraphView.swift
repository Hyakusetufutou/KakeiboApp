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

    var body: some View {
        NavigationStack {
            VStack {

                navigationTitle()

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
        }
        .onAppear {
            updateSummaries(for: selectedType)
        }
        .onChange(of: selectedType) { newValue in
            updateSummaries(for: newValue)
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
    GraphView()
}
