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

    static func stringToColor(_ colorString: String) -> Color {
        switch colorString {
        case "red":
            return .red
        case "blue":
            return .blue
        case "yellow":
            return .yellow
        case "purple":
            return .purple
        case "white":
            return .white
        default:
            return .white
        }
    }

    static func colorToString(_ color: Color) -> String {
        switch color {
        case .red:
            return "red"
        case .blue:
            return "blue"
        case .yellow:
            return "yellow"
        case .purple:
            return "purple"
        default:
            return "white"
        }
    }
}
