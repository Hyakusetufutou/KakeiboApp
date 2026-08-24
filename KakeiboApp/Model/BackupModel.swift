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
}
