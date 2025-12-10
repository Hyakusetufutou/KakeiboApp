//
//  ChangeMonthView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/12/04
//
//

import SwiftUI

struct ChangeMonthView: View {
    @Binding var date: Date
    var onPreviousMonth: () -> Void
    var onNextMonth: () -> Void
    var body: some View {
        // MARK: - 月切り替え
        HStack {
            Button {
                onPreviousMonth()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(format(date: date, format: "yyyy年 M月"))
                .font(.title3.bold())

            Spacer()

            Button {
                onNextMonth()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}
