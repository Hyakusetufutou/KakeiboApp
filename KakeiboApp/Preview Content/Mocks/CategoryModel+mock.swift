//
//  CategoryModel+mock.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import Foundation

extension CategorySummary {
    static let mock1 = CategorySummary(
        categoryID: UUID(),
        categoryName: "食費",
        type: .expense,
        totalAmount: 1000,
        color: .blue,
        transactions: [.mock1]
    )

    static let mock2 = CategorySummary(
        categoryID: UUID(),
        categoryName: "給料",
        type: .income,
        totalAmount: 200000,
        color: .yellow,
        transactions: [.mock2]
    )

    static let mock3 = CategorySummary(
        categoryID: UUID(),
        categoryName: "日用品",
        type: .expense,
        totalAmount: 500,
        color: .orange,
        transactions: [.mock3]
    )
}
