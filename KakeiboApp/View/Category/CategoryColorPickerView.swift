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

            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ForEach(AppTheme.categoryColors.prefix(6), id: \.self) {
                        colorButton(color: $0)
                    }
                }

                GridRow {
                    ForEach(AppTheme.categoryColors.dropFirst(6), id: \.self) {
                        colorButton(color: $0)
                    }
                }
            }
        }
    }

    private func colorButton(color: Color) -> some View {
        let isSelected = color == selectedColor.color

        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedColor = CategoryColor(color: color)
            }
        } label: {
            Circle()
                .fill(color)
                .frame(width: 34, height: 34)
                .overlay {
                    Circle()
                        .strokeBorder(Color(.systemBackground), lineWidth: isSelected ? 2 : 0)
                }
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.3), radius: 1)
                    }
                }
                .scaleEffect(isSelected ? 1.15 : 1)
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .accessibilityLabel("カラーを選択")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}
