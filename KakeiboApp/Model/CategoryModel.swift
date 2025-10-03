//
//  CategoryModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

struct CategoryModel: Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: Color
    let type: TransactionType
    let isDefault: Bool

    init(id: UUID = UUID(), name: String, color: Color, type: TransactionType, isDefault: Bool) {
        self.id = id
        self.name = name
        self.color = color
        self.type = type
        self.isDefault = isDefault
    }
}

struct CategorySummary: Identifiable {
    var id: UUID { categoryID }
    let categoryID: UUID
    let categoryName: String
    let type: TransactionType
    let totalAmount: Double
    let color: Color
    let transactions: [TransactionModel]
}

extension CategoryEntity {
    func toModel() -> CategoryModel {
        return CategoryModel(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            color: AppTheme.stringToColor(self.color ?? "white"),
            type: TransactionType(rawValue: self.type ?? "支出") ?? .expense,
            isDefault: false
        )
    }
}
