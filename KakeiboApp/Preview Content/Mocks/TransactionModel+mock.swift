//
//  TransactionModel+mock.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/11
//
//

import Foundation

extension TransactionModel {
    static let mock1 = try! TransactionModel(
        title: "食費",
        memo: "お肉代",
        amount: Decimal(1000),
        date: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        type: .expense,
        categoryId: CategoryModel.mock1.id
    )
    static let mock2 = try! TransactionModel(
        title: "給料",
        memo: "給料",
        amount: Decimal(200000),
        date: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        type: .income,
        categoryId: CategoryModel.mock3.id
    )
    static let mock3 = try! TransactionModel(
        title: "ティッシュ",
        memo: "ティッシュ",
        amount: Decimal(500),
        date: Date(),
        createdAt: Date(),
        updatedAt: Date(),
        type: .expense,
        categoryId: CategoryModel.mock2.id
    )
}
