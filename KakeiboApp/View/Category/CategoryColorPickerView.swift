//
//  CategoryColorPickerView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/03
//
//

import SwiftUI

struct CategoryColorPickerView: View {
    @Binding var selectedColor: CategoryColor

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("カラー")
                .font(.caption)
                .foregroundStyle(.secondary)

            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6),
                spacing: 12
            ) {
                ForEach(AppTheme.categoryColors, id: \.self) { color in
                    colorButton(color: color)
                }
            }
        }
    }

    private func colorButton(color: Color) -> some View {
        let isSelected = color == selectedColor.color

        return Circle()
            .fill(color)
            .frame(width: 34, height: 34)
            .overlay {
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isSelected ? 1.15 : 1)
            .animation(
                .spring(response: 0.35, dampingFraction: 0.7),
                value: selectedColor
            )
            .onTapGesture {
                selectedColor = CategoryColor(color: color)
            }
    }
}
