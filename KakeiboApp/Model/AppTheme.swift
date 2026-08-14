//
//  AppTheme.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import SwiftUI

enum AppTheme {
    static let background = Color(.systemGroupedBackground)
    static let secondaryBackground = Color(.secondarySystemGroupedBackground)
    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let segmentBackground = Color("SegmentBackground")

    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)

    static let categoryColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal, .blue, .indigo, .purple, .pink, .brown, .gray,
    ]

    static func stringToColor(_ colorString: String) -> Color {
        switch colorString {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "mint":
            return .mint
        case "teal":
            return .teal
        case "blue":
            return .blue
        case "indigo":
            return .indigo
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "brown":
            return .brown
        case "gray":
            return .gray
        default:
            return .blue
        }
    }

    static func colorToString(_ color: Color) -> String {
        switch color {
        case .red:
            return "red"
        case .orange:
            return "orange"
        case .yellow:
            return "yellow"
        case .green:
            return "green"
        case .mint:
            return "mint"
        case .teal:
            return "teal"
        case .blue:
            return "blue"
        case .indigo:
            return "indigo"
        case .purple:
            return "purple"
        case .pink:
            return "pink"
        case .brown:
            return "brown"
        case .gray:
            return "gray"
        default:
            return "blue"
        }
    }
}
