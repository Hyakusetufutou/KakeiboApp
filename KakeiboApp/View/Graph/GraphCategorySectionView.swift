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
        VStack(spacing: 24) {
            totalAmountView
            pieChartView
            categoryListView
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(.snappy, value: graphViewModel.categorySummaries.map(\.id))
    }

    private var totalAmountView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(graphViewModel.totalTitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(currencyString(graphViewModel.totalAmount, allowedDigits: 0))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var pieChartView: some View {
        PieChartView(data: graphViewModel.categorySummaries)
            .frame(height: 200)
            .padding(.vertical, 8)
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
        .background(AppTheme.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func categoryRow(summary: CategorySummary) -> some View {
        NavigationLink(value: summary.categoryID) {
            HStack(spacing: 12) {
                Circle()
                    .fill(summary.color)
                    .frame(width: 10, height: 10)

                Text(summary.categoryName)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Text(currencyString(summary.totalAmount, allowedDigits: 2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
