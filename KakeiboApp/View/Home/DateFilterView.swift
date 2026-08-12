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
        NavigationStack {
            List {
                Section {
                    datePickerRow(title: "開始日", date: $start, range: ...end)
                    datePickerRow(title: "終了日", date: $end, range: start...)
                }
            }
            .navigationTitle("期間を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: onClose)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("適用") {
                        onSubmit(start, end)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Components

    private func datePickerRow(
        title: String,
        date: Binding<Date>,
        range: PartialRangeThrough<Date>
    ) -> some View {
        DatePicker(title, selection: date, in: range, displayedComponents: [.date])
            .environment(\.locale, Locale(identifier: "ja_JP"))
    }

    private func datePickerRow(
        title: String,
        date: Binding<Date>,
        range: PartialRangeFrom<Date>
    ) -> some View {
        DatePicker(title, selection: date, in: range, displayedComponents: [.date])
            .environment(\.locale, Locale(identifier: "ja_JP"))
    }
}

#Preview {
    DateFilterView(
        start: Date().startOfMonth,
        end: Date().endOfMonth,
        onSubmit: { _, _ in },
        onClose: {}
    )
}
