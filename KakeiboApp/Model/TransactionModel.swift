//
//  TransactionModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/09
//
//

import Foundation

struct TransactionModel: Identifiable, Hashable {
    let id: UUID
    let title: String
    let memo: String
    let amount: Decimal
    let date: Date
    let createdAt: Date
    let updatedAt: Date
    let type: TransactionType
    let categoryId: UUID

    init(
        id: UUID = UUID(),
        title: String,
        memo: String,
        amount: Decimal,
        date: Date,
        createdAt: Date,
        updatedAt: Date,
        type: TransactionType,
        categoryId: UUID
    ) {
        self.id = id
        self.title = title
        self.memo = memo
        self.amount = amount
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.type = type
        self.categoryId = categoryId
    }
}

enum TransactionType: String, CaseIterable, Identifiable {
    case income = "収入"
    case expense = "支出"

    var id: Self { self }

    var imageName: String {
        switch self {
        case .income:
            return "tray.and.arrow.down.fill"
        case .expense:
            return "tray.and.arrow.up.fill"
        }
    }
}

extension TransactionEntity {
    func toModel() throws -> TransactionModel {
        guard let type = TransactionType(rawValue: self.type) else {
            throw TransactionMapperError.invalidType
        }
        return TransactionModel(
            id: id,
            title: title,
            memo: memo,
            amount: self.amount.decimalValue,
            date: date,
            createdAt: createdAt,
            updatedAt: updatedAt,
            type: type,
            categoryId: self.category.id
        )
    }
}
