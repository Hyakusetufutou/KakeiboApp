//
//  BackupModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/24
//
//

import Foundation

struct BackupData: Codable {
    let version: Int
    let createdAt: Date
    let categories: [BackupCategoryModel]
    let transactions: [BackupTransactionModel]
}

struct BackupCategoryModel: Codable {
    let id: UUID
    let name: String
    let color: CategoryColor
    let type: TransactionType
    let isDefault: Bool

    init(from category: CategoryModel) {
        self.id = category.id
        self.name = category.name
        self.color = category.color
        self.type = category.type
        self.isDefault = category.isDefault
    }
}

struct BackupTransactionModel: Codable {
    let id: UUID
    let title: String
    let memo: String
    let amount: Decimal
    let date: Date
    let createdAt: Date
    let updatedAt: Date
    let type: TransactionType
    let categoryId: UUID

    init(from transaction: TransactionModel) {
        self.id = transaction.id
        self.title = transaction.title
        self.memo = transaction.memo
        self.amount = transaction.amount
        self.date = transaction.date
        self.createdAt = transaction.createdAt
        self.updatedAt = transaction.updatedAt
        self.type = transaction.type
        self.categoryId = transaction.categoryId
    }
}
