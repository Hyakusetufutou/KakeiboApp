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
    // MARK: - Published Properties
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

    // MARK: - Computed Properties
    var selectedCategory: CategoryModel? {
        categories.first { $0.id == selectedCategoryId }
    }

    var availableCategories: [CategoryModel] {
        categories.filter { $0.type == type }
    }

    var isFormValid: Bool {
        validationError == nil
    }

    private var originalCreatedAt: Date?

    private var validationError: ValidationError? {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return .emptyTitle
        }

        guard let amountValue = Double(amount), amountValue > 0 else {
            return .invalidAmount
        }

        if selectedCategoryId == nil {
            return .noCategory
        }

        return nil
    }

    // MARK: - Dependencies
    private let categoryStore: CategoryStoreProtocol
    private let transactionStore: TransactionStoreProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(categoryStore: CategoryStoreProtocol, transactionStore: TransactionStoreProtocol) {
        self.categoryStore = categoryStore
        self.transactionStore = transactionStore
        setupBindings()
        bindError()
    }

    // MARK: - Public Methods
    func presentInputView(for transaction: TransactionModel? = nil) {
        if let transaction = transaction {
            restoreForm(from: transaction)
            isEdit = true
        } else {
            resetForm()
            isEdit = false
        }
        isPresentInputView = true
    }

    func save() async {
        // Clear previous error
        errorMessage = nil

        // Validate form
        if let error = validationError {
            errorMessage = error.localizedDescription
            return
        }

        // Create transaction model
        guard let transaction = createTransaction() else {
            errorMessage = "トランザクションの作成に失敗しました"
            return
        }

        // Save transaction
        isLoading = true
        defer { isLoading = false }

        if isEdit {
            await transactionStore.update(transaction)
        } else {
            await transactionStore.add(transaction)
        }

        // Success: close the view
        closeInputView()
    }

    func cancel() {
        closeInputView()
    }

    func resetSelectedCategory() {
        selectedCategoryId = nil
    }

    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Methods
    private func setupBindings() {
        bindCategories()
        observeTypeChange()
    }

    private func bindCategories() {
        categoryStore.categories
            .receive(on: DispatchQueue.main)
            .assign(to: &$categories)
    }

    private func observeTypeChange() {
        $type
            .dropFirst()
            .sink { [weak self] _ in
                self?.resetSelectedCategory()
            }
            .store(in: &cancellables)
    }

    private func resetForm() {
        id = UUID()
        title = ""
        memo = ""
        amount = ""
        date = Date()
        type = .expense
        selectedCategoryId = nil
        originalCreatedAt = nil
        errorMessage = nil
    }

    private func restoreForm(from transaction: TransactionModel) {
        id = transaction.id
        title = transaction.title
        memo = transaction.memo
        amount = String(Int(transaction.amount))
        date = transaction.date
        type = transaction.type
        selectedCategoryId = transaction.categoryId
        errorMessage = nil
    }

    private func createTransaction() -> TransactionModel? {
        guard let amountValue = Double(amount),
            let categoryId = selectedCategoryId
        else {
            return nil
        }

        let now = Date()

        return TransactionModel(
            id: id,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            memo: memo.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amountValue,
            date: date,
            createdAt: isEdit ? (originalCreatedAt ?? now) : now,
            updatedAt: now,
            type: type,
            categoryId: categoryId
        )
    }

    private func closeInputView() {
        isPresentInputView = false
        errorMessage = nil
        resetForm()
    }

    private func bindError() {
        transactionStore.errorPublisher
            .map(ErrorMapper.message)
            .receive(on: DispatchQueue.main)
            .assign(to: &$errorMessage)
    }
}

// MARK: - Validation Error
extension TransactionInputViewModel {
    enum ValidationError: LocalizedError {
        case emptyTitle
        case invalidAmount
        case noCategory

        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "タイトルを入力してください"
            case .invalidAmount:
                return "有効な金額を入力してください"
            case .noCategory:
                return "カテゴリを選択してください"
            }
        }
    }
}
