//
//  CalendarModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/06
//
//

import Foundation

struct DailySummary {
    let id = UUID()
    let date: Date
    let income: Double
    let expense: Double
    let transactions: [TransactionModel]
}
