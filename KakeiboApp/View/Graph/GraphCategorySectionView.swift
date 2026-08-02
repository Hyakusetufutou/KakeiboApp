//
//  GraphCategorySectionView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/01
//
//

import SwiftUI

struct GraphCategorySectionView: View {
    @ObservedObject var graphViewModel: GraphViewModel

    var body: some View {
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
        NavigationLink(value: summary.categoryID) {
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
}
