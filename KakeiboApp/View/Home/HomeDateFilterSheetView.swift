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
            start: homeViewModel.startDate,
            end: homeViewModel.endDate,
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
