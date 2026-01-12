//
//  AppTheme.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import SwiftUI

struct AppTheme: Equatable {
    let primary: Color
    let background: Color

    static let light = AppTheme(
        primary: Color("PrimaryLight"),
        background: Color("BackgroundLight")
    )

    static let dark = AppTheme(
        primary: Color("PrimaryDark"),
        background: Color("BackgroundDark")
    )

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
