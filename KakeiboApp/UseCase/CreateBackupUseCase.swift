//
//  CreateBackupUseCase.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/24
//
//

import Foundation

protocol CreateBackupUseCaseProtocol: Sendable {
    func execute() async throws -> Data
}

final class CreateBackupUseCase: CreateBackupUseCaseProtocol {
    private let backupRepository: BackupRepositoryProtocol
    private let backupService: BackupServiceProtocol

    init(
        backupRepository: BackupRepositoryProtocol,
        backupService: BackupServiceProtocol
    ) {
        self.backupRepository = backupRepository
        self.backupService = backupService
    }

    func execute() async throws -> Data {
        let backup = try await backupRepository.create()
        let categories = try backup.categories.map {
            try $0.toCategoryModel()
        }
        let transactions = try backup.transactions.map {
            try $0.toTransactionModel()
        }

        return try backupService.createBackUp(
            categories: categories,
            transactions: transactions
        )
    }
}
