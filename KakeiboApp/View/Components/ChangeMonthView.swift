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
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(format(date: date, format: "yyyy年 M月"))
                .font(.title3.bold())

            Spacer()

            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
}
