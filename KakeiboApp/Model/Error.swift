//
//  Error.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import Foundation

enum CustomError: Equatable, LocalizedError {
    case categoryNotFoundError
    case transactionNotFoundError
    case saveError
    case fetchError(String)
    case invalidData
    case cannotDeletedefaultCategory

    var errorDescription: String? {
        switch self {
        case .categoryNotFoundError:
            return "カテゴリが見つかりません"
        case .transactionNotFoundError:
            return "取引が見つかりません"
        case .saveError:
            return "保存に失敗しました"
        case .fetchError(let message):
            return "取得に失敗しました: \(message)"
        case .invalidData:
            return "不正なデータです"
        case .cannotDeletedefaultCategory:
            return "デフォルトカテゴリのため削除できません"
        }
    }
}

enum CategoryMapperError: LocalizedError {
    case invalidColor
    case invalidType

    var errorDescription: String? {
        switch self {
        case .invalidColor:
            return "カテゴリの色が無効です"
        case .invalidType:
            return "カテゴリの種類が無効です"
        }
    }
}

enum TransactionMapperError: LocalizedError {
    case invalidType

    var errorDescription: String? {
        switch self {
        case .invalidType:
            return "Transactionの種別が無効です"
        }
    }
}

enum ErrorMapper {
    static func message(for error: Error) -> String {
        return error.localizedDescription
    }
}
