//
//  TransactionModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/09
//
//

import Foundation

struct TransactionModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let memo: String
    let amount: Double
    let date: Date
    let type: TransactionType
}

enum TransactionType: String, CaseIterable {
    case income = "収入"
    case expense = "支出"
}
