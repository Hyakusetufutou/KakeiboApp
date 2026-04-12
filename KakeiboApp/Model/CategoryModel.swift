//
//  CategoryModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

enum CategoryColor: String, CaseIterable {
    case red
    case orange
    case yellow
    case green
    case mint
    case teal
    case blue
    case indigo
    case purple
    case pink
    case brown
    case gray

    init(color: Color) {
        switch color {
        case .red: self = .red
        case .orange: self = .orange
        case .yellow: self = .yellow
        case .green: self = .green
        case .mint: self = .mint
        case .teal: self = .teal
        case .blue: self = .blue
        case .indigo: self = .indigo
        case .purple: self = .purple
        case .pink: self = .pink
        case .brown: self = .brown
        case .gray: self = .gray
        default: self = .blue
        }
    }

    var color: Color {
        switch self {
        case .red: .red
        case .orange: .orange
        case .yellow: .yellow
        case .green: .green
        case .mint: .mint
        case .teal: .teal
        case .blue: .blue
        case .indigo: .indigo
        case .purple: .purple
        case .pink: .pink
        case .brown: .brown
        case .gray: .gray
        }
    }
}

struct CategoryModel: Identifiable, Hashable {
    let id: UUID
    let name: String
    let color: CategoryColor
    let type: TransactionType
    let isDefault: Bool

    init(
        id: UUID = UUID(),
        name: String,
        color: CategoryColor,
        type: TransactionType,
        isDefault: Bool
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.type = type
        self.isDefault = isDefault
    }
}

extension CategoryModel {
    static let defaults: [CategoryModel] = [
        // 支出
        CategoryModel(
            id: UUID(uuidString: "A0000001-0000-0000-0000-000000000000")!,
            name: "食費",
            color: .orange,
            type: .expense,
            isDefault: true
        ),
        CategoryModel(
            id: UUID(uuidString: "A0000002-0000-0000-0000-000000000000")!,
            name: "交通費",
            color: .blue,
            type: .expense,
            isDefault: true
        ),
        CategoryModel(
            id: UUID(uuidString: "A0000003-0000-0000-0000-000000000000")!,
            name: "日用品",
            color: .green,
            type: .expense,
            isDefault: true
        ),
        CategoryModel(
            id: UUID(uuidString: "A0000004-0000-0000-0000-000000000000")!,
            name: "趣味",
            color: .purple,
            type: .expense,
            isDefault: true
        ),
        CategoryModel(
            id: UUID(uuidString: "A0000005-0000-0000-0000-000000000000")!,
            name: "その他",
            color: .red,
            type: .expense,
            isDefault: true
        ),
        // 収入
        CategoryModel(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000000")!,
            name: "給与",
            color: .teal,
            type: .income,
            isDefault: true
        ),
        CategoryModel(
            id: UUID(uuidString: "B0000002-0000-0000-0000-000000000000")!,
            name: "副業",
            color: .indigo,
            type: .income,
            isDefault: true
        ),
    ]
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
    func toModel() throws -> CategoryModel {
        guard let id = self.id,
            let name = self.name
        else {
            throw CustomError.invalidData
        }

        guard let rawColor = self.color,
            let color = CategoryColor(rawValue: rawColor)
        else {
            throw CustomError.invalidData
        }

        guard let rawType = self.type,
            let type = TransactionType(rawValue: rawType)
        else {
            throw CustomError.invalidData
        }

        return CategoryModel(
            id: id,
            name: name,
            color: color,
            type: type,
            isDefault: self.isDefault
        )
    }
}
