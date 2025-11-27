//
//  TabModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import Foundation

enum TabModel: String, CaseIterable {
    case home = "house"
    case calendar = "calendar"
    case graph = "chart.pie"
    case setting = "gearshape"

    var title: String {
        switch self {
        case .home: "ホーム"
        case .calendar: "カレンダー"
        case .graph: "グラフ"
        case .setting: "設定"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
