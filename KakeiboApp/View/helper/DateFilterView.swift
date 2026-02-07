//
//  DateFilterView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import SwiftUI

struct DateFilterView: View {
    @Binding var start: Date
    @Binding var end: Date
    var onSubmit: (Date, Date) -> Void
    var onClose: () -> Void
    var body: some View {
        VStack(spacing: 15) {
            DatePicker("開始日", selection: $start, displayedComponents: [.date])
                .environment(\.locale, Locale(identifier: "ja_JP"))

            DatePicker("終了日", selection: $end, displayedComponents: [.date])
                .environment(\.locale, Locale(identifier: "ja_JP"))

            HStack(spacing: 15) {
                Button("キャンセル") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .tint(.red)

                Button("適用") {
                    onSubmit(start, end)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .tint(.blue)
            }
            .padding(.top, 10)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.background)
                .shadow(radius: 10)
        )
        .padding(.horizontal, 30)
    }
}

#Preview {
    DateFilterView(
        start: .constant(Date()),
        end: .constant(Date()),
        onSubmit: { _, _ in },
        onClose: {}
    )
}
