//
//  HomeDateFilterSheetView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/02
//
//

import SwiftUI

struct HomeDateFilterSheetView: View {
    @ObservedObject var homeViewModel: HomeViewModel

    var body: some View {
        DateFilterView(
            start: homeViewModel.dateRange.start,
            end: homeViewModel.dateRange.end,
            onSubmit: { start, end in
                homeViewModel.dateRange = DateRange(start: start, end: end)
                homeViewModel.showFilterView = false
            },
            onClose: {
                homeViewModel.showFilterView = false
            }
        )
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
