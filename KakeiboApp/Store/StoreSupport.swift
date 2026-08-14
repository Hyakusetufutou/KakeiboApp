//
//  StoreSupport.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/07/26
//
//

import Foundation

enum StoreSupport {
    static func normalizedSearchText(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
