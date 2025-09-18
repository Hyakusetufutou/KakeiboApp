//
//  TransactionModel+mock.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import Foundation

extension TransactionModel {
    static let mock1 = TransactionModel(
        title: "食費",
        memo: "お肉代",
        amount: Double(1000),
        date: Date(),
        type: .expense
    )
    static let mock2 = TransactionModel(
        title: "給料",
        memo: "給料",
        amount: Double(200000),
        date: Date(),
        type: .income
    )
    static let mock3 = TransactionModel(
        title: "ティッシュ",
        memo: "ティッシュ",
        amount: Double(500),
        date: Date(),
        type: .expense
    )
}
