//
//  RestoreBackupUseCase.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/24
//
//

import Foundation

protocol RestoreBackupUseCaseProtocol {
    func execute(data: Data) async throws
}

final class RestoreBackupUseCase: RestoreBackupUseCaseProtocol {
    private let backupRepository: BackupRepositoryProtocol
    private let backupService: BackupServiceProtocol

    init(
        backupRepository: BackupRepositoryProtocol,
        backupService: BackupServiceProtocol
    ) {
        self.backupRepository = backupRepository
        self.backupService = backupService
    }

    func execute(data: Data) async throws {
        let backup = try backupService.decodeBackUp(from: data)
        let categories = try backup.categories.map {
            try $0.toCategoryModel()
        }
        let transactions = try backup.transactions.map {
            try $0.toTransactionModel()
        }

        try await backupRepository.restore(addCategories: categories, addTransactions: transactions)
    }
}
