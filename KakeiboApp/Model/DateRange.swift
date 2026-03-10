//
//  DateRange.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/02/07
//
//

import Foundation

struct DateRange {
    let start: Date
    let end: Date

    init(start: Date = Date().startOfMonth, end: Date = Date().endOfMonth) {
        if start <= end {
            self.start = start
            self.end = end
        } else {
            self.start = end
            self.end = start
        }
    }

    func contains(_ date: Date) -> Bool {
        return date >= start && date <= end
    }

    func withStart(_ newStart: Date) -> DateRange {
        DateRange(start: newStart, end: end)
    }

    func withEnd(_ newEnd: Date) -> DateRange {
        DateRange(start: start, end: newEnd)
    }
}
