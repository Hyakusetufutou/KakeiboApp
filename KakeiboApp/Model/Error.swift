//
//  Error.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import Foundation

enum CustomError: Error, Equatable {
    case categoryNotFoundError
    case transactionNotFoundError
    case saveError
    case fetchError(String)
    case invalidData
    case cannotDeletedefaultCategory

    var description: String {
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
