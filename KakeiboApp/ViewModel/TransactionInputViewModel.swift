//
//  TransactionInputViewModel.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/09
//
//

import Foundation
import Combine

@MainActor
final class TransactionInputViewModel: ObservableObject {
    @Published private(set) var categories: [CategoryModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published var isPresentInputView = false
    @Published var isEdit = false

    @Published var id = UUID()
    @Published var title = ""
    @Published var memo = ""
    @Published var amount = ""
    @Published var date = Date()
    @Published var type: TransactionType = .expense
    @Published var selectedCategoryId: UUID?

    var selectedCategory: CategoryModel? {
        categories.first { $0.id == selectedCategoryId }
    }

    var availableCategories: [CategoryModel] {
        categories.filter { $0.type == type }
    }

    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        bindCategories()
        bindLoadingState()
        bindErrorMessages()
        observeTypeChange()
    }

    func resetSelectedCategory() {
        selectedCategoryId = nil
    }

    func presentInputView(_ transactionItem: TransactionModel? = nil) {
        if let transaction = transactionItem {
            restore(from: transaction)
            isEdit = true
        } else {
            reset()
            isEdit = false
        }
        isPresentInputView = true
    }

    func save() async {
        guard isValid() else {
            errorMessage = validationErrorMessage()
            return
        }

        let transaction = TransactionModel(
            id: id,
            title: title,
            memo: memo,
            amount: Double(amount) ?? 0,
            date: date,
            createAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: selectedCategoryId ?? UUID()
        )

        isLoading = true
        if isEdit {
            await transactionStore.update(transaction)
        } else {
            await transactionStore.add(transaction)
        }
        isLoading = false

        reset()
        cancel()
    }

    func cancel() {
        isPresentInputView = false
        errorMessage = nil
    }

    func isValid() -> Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard let amountValue = Double(amount), amountValue > 0 else { return false }
        guard selectedCategoryId != nil else { return false }
        return true
    }

    private func reset() {
        id = UUID()
        title = ""
        memo = ""
        amount = ""
        date = Date()
        type = .expense
        selectedCategoryId = nil
    }

    private func restore(from transaction: TransactionModel) {
        id = transaction.id
        title = transaction.title
        memo = transaction.memo ?? ""
        amount = String(Int(transaction.amount))
        date = transaction.date
        type = transaction.type
        selectedCategoryId = transaction.categoryId
    }

    private func validationErrorMessage() -> String {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "タイトルを入力してください"
        }
        if Double(amount) == nil || Double(amount)! <= 0 {
            return "有効な金額を入力してください"
        }
        if selectedCategoryId == nil {
            return "カテゴリを選択してください"
        }
        return "入力内容を確認してください"
    }

    private func bindCategories() {
        categoryStore.categories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] categories in
                self?.categories = categories
            }
            .store(in: &cancellables)
    }

    private func bindLoadingState() {
        Publishers.CombineLatest(
            transactionStore.isLoading,
            categoryStore.isLoading
        )
        .map { $0 || $1 }
        .receive(on: DispatchQueue.main)
        .assign(to: &$isLoading)
    }

    private func bindErrorMessages() {
        Publishers.Merge(
            transactionStore.errorMessage,
            categoryStore.errorMessage
        )
        .receive(on: DispatchQueue.main)
        .assign(to: &$errorMessage)
    }

    private func observeTypeChange() {
        $type
            .dropFirst()
            .sink { [weak self] _ in
                self?.selectedCategoryId = nil
            }
            .store(in: &cancellables)
    }
}
