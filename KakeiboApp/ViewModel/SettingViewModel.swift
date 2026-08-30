//
//  SettingViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/24
//
//

import Foundation

@MainActor
final class SettingViewModel: ObservableObject {

    @Published private(set) var isProcessing = false
    @Published var errorMessage: String?

    private let createBackupUseCase: CreateBackupUseCaseProtocol
    private let restoreBackupUseCase: RestoreBackupUseCaseProtocol
    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol

    init(
        createBackupUseCase: CreateBackupUseCaseProtocol,
        restoreBackupUseCase: RestoreBackupUseCaseProtocol,
        categoryStore: CategoryStoreProtocol,
        transactionStore: TransactionStoreProtocol
    ) {
        self.createBackupUseCase = createBackupUseCase
        self.restoreBackupUseCase = restoreBackupUseCase
        self.transactionStore = transactionStore
        self.categoryStore = categoryStore
    }

    func createBackup() async -> Data? {
        isProcessing = true
        errorMessage = nil

        defer {
            isProcessing = false
        }

        do {
            return try await createBackupUseCase.execute()
        } catch {
            errorMessage = ErrorMapper.message(for: error)
            return nil
        }
    }

    func restoreBackup(from data: Data) async {
        isProcessing = true
        errorMessage = nil

        defer {
            isProcessing = false
        }

        do {
            try await restoreBackupUseCase.execute(data: data)
            await transactionStore.load()
            await categoryStore.reload()
        } catch {
            errorMessage = ErrorMapper.message(for: error)
        }
    }
}
