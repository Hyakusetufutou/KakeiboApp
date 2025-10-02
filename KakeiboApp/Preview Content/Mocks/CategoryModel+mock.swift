//
//  CategoryModel+mock.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import Foundation

extension CategoryModel {
    static let mock1 = CategoryModel(name: "食費", color: .blue, type: .expense, isDefault: true)
    static let mock2 = CategoryModel(name: "日用品", color: .purple, type: .expense, isDefault: true)
    static let mock3 = CategoryModel(name: "給料", color: .yellow, type: .income, isDefault: true)
}

extension CategorySummary {
    static let mock1 = CategorySummary(
        categoryID: UUID(),
        categoryName: CategoryModel.mock1.name,
        type: .expense,
        totalAmount: 1000,
        color: .blue,
        transactions: [.mock1]
    )

    static let mock2 = CategorySummary(
        categoryID: UUID(),
        categoryName: CategoryModel.mock3.name,
        type: .income,
        totalAmount: 200000,
        color: .yellow,
        transactions: [.mock2]
    )

    static let mock3 = CategorySummary(
        categoryID: UUID(),
        categoryName: CategoryModel.mock2.name,
        type: .expense,
        totalAmount: 500,
        color: .orange,
        transactions: [.mock3]
    )
}
