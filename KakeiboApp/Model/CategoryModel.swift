//
//  CategoryModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

struct CategoryModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let color: Color
    let type: TransactionType
    let isDefault: Bool
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
