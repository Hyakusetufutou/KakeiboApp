//
//  DateFilterView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import SwiftUI

struct DateFilterView: View {
    @State var start: Date
    @State var end: Date
    var onSubmit: (Date, Date) -> Void
    var onClose: () -> Void
    var body: some View {
        VStack(spacing: 15) {
            DatePicker("開始日", selection: $start, displayedComponents: [.date])
                .environment(\.locale, Locale(identifier: "ja_JP"))

            DatePicker("終了日", selection: $end, displayedComponents: [.date])
                .environment(\.locale, Locale(identifier: "ja_JP"))

            HStack(spacing: 15) {
                Button("中止") {
                    onClose()
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 5))
                .tint(.red)

                Button("確定") {
                    onSubmit(start, end)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 5))
                .tint(.blue)  //@@@
            }
            .padding(.top, 10)
        }
        .padding(15)
        .background(.bar, in: .rect(cornerRadius: 10))
        .padding(.horizontal, 30)
    }
}

#Preview {
    DateFilterView(start: Date(), end: Date(), onSubmit: { _, _ in }, onClose: {})
}
