//
//  Date+Extensions.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/10
//
//

import Foundation

extension Date {
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)

        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .init(month: 1, day: -1), to: self.startOfMonth) ?? self
    }
}
