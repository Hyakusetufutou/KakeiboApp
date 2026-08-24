//
//  BackupService.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/24
//
//

import Foundation

protocol BackupServiceProtocol {
    func createBackUp(categories: [CategoryModel], transactions: [TransactionModel]) throws -> Data
    func restoreBackup(from data: Data) throws -> BackupData
}

final class BackupService: BackupServiceProtocol {
    func createBackUp(categories: [CategoryModel], transactions: [TransactionModel]) throws -> Data
    {
        let backup = BackupData(
            version: 1,
            createdAt: Date(),
            categories: categories.map({ BackupCategoryModel(from: $0) }),
            transactions: transactions.map({ BackupTransactionModel(from: $0) })
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]

        return try encoder.encode(backup)
    }

    func restoreBackup(from data: Data) throws -> BackupData {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(BackupData.self, from: data)
    }
}
