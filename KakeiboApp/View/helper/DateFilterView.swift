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

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView

            // Date Pickers
            datePickersSection

            // Action Buttons
            actionButtons
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(
                    color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                    radius: 20,
                    y: 10
                )
        )
        .padding(.horizontal, 30)
    }

    // MARK: - Components

    private var headerView: some View {
        HStack {
            Text("期間を選択")
                .font(.headline)

            Spacer()

            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }

    private var datePickersSection: some View {
        VStack(spacing: 16) {
            datePickerRow(title: "開始日", date: $start, range: ...end)

            Divider()

            datePickerRow(title: "終了日", date: $end, range: start...)
        }
        .padding(.vertical, 8)
    }

    private func datePickerRow(
        title: String,
        date: Binding<Date>,
        range: PartialRangeThrough<Date>
    ) -> some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            DatePicker(
                "",
                selection: date,
                in: range,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }

    private func datePickerRow(
        title: String,
        date: Binding<Date>,
        range: PartialRangeFrom<Date>
    ) -> some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            DatePicker(
                "",
                selection: date,
                in: range,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .environment(\.locale, Locale(identifier: "ja_JP"))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("キャンセル") {
                onClose()
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
            .frame(maxWidth: .infinity)

            Button("適用") {
                onSubmit(start, end)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview("Light Mode") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        DateFilterView(
            start: .constant(Date()),
            end: .constant(Date()),
            onSubmit: { _, _ in },
            onClose: {}
        )
    }
    .preferredColorScheme(.light)
}

#Preview("Dark Mode") {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()

        DateFilterView(
            start: .constant(Date()),
            end: .constant(Date()),
            onSubmit: { _, _ in },
            onClose: {}
        )
    }
    .preferredColorScheme(.dark)
}
