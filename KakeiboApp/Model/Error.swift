//
//  Error.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import Foundation

enum CustomError: Error {
    case saveError
    case categoryNotFoundError
    case transactionNotFoundError

    var description: String {
        switch self {
        case .saveError:
            return "保存に失敗しました"
        case .categoryNotFoundError:
            return "カテゴリが見つかりませんでした"
        case .transactionNotFoundError:
            return "取引が見つかりませんでしあ"
        }
    }
}
