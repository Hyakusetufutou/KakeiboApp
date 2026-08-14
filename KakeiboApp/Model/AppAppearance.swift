//
//  AppAppearance.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/13
//
//

import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: Self { self }

    var title: String {
        switch self {
        case .system:
            "システム"
        case .light:
            "ライト"
        case .dark:
            "ダーク"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}
