//
//  TransactionInputViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("TransactionInputViewModel のテスト")
struct TransactionInputViewModelTests {

    private func makeSUT() async throws -> (
        TransactionInputViewModel, TransactionStore, CategoryModel
    ) {
        let container = PersistenceController(inMemory: true).container
        let categoryRepo = CategoryRepository(container: container)
        let transactionRepo = TransactionRepository(container: container)

        let categoryStore = CategoryStore(repository: categoryRepo, autoLoad: false)
        let transactionStore = TransactionStore(repository: transactionRepo)

        let dummyCategory = try CategoryModel(
            id: UUID(),
            name: "食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await categoryStore.add(dummyCategory)

        let viewModel = TransactionInputViewModel(
            categoryStore: categoryStore,
            transactionStore: transactionStore
        )
        try await Task.sleep(nanoseconds: 50_000_000)

        return (viewModel, transactionStore, dummyCategory)
    }

    // MARK: - バリデーションテスト

    @Test("各バリデーションエラー分岐の網羅（タイトル空、金額不正、カテゴリ未選択）")
    func validationErrorsCoverage() async throws {
        let (viewModel, _, dummyCategory) = try await makeSUT()

        // 1. タイトル空
        viewModel.presentInputView()
        viewModel.title = "   "
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = dummyCategory.id
        #expect(viewModel.isFormValid == false)
        let saveResult1 = await viewModel.save()
        #expect(saveResult1 == false)
        #expect(
            viewModel.errorMessage
                == ErrorMapper.message(for: TransactionInputViewModel.ValidationError.emptyTitle)
        )

        // 2. 金額不正 (非数値 / 0以下)
        viewModel.title = "テスト"
        viewModel.amount = "abc"
        #expect(viewModel.isFormValid == false)
        let saveResult2 = await viewModel.save()
        #expect(saveResult2 == false)
        #expect(
            viewModel.errorMessage
                == ErrorMapper.message(for: TransactionInputViewModel.ValidationError.invalidAmount)
        )

        // 3. カテゴリ未選択
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = nil
        #expect(viewModel.isFormValid == false)
        let saveResult3 = await viewModel.save()
        #expect(saveResult3 == false)
        #expect(
            viewModel.errorMessage
                == ErrorMapper.message(for: TransactionInputViewModel.ValidationError.noCategory)
        )

        // 正常入力
        viewModel.selectedCategoryId = dummyCategory.id
        #expect(viewModel.isFormValid == true)
    }

    // MARK: - 状態変化と算出プロパティのテスト

    @Test("type 変更時の selectedCategoryId リセットおよび availableCategories と selectedCategory の算出結果")
    func typeChangeAndComputedProperties() async throws {
        let (viewModel, _, dummyCategory) = try await makeSUT()

        viewModel.type = .expense
        #expect(viewModel.availableCategories.contains(where: { $0.id == dummyCategory.id }))

        viewModel.selectedCategoryId = dummyCategory.id
        #expect(viewModel.selectedCategory?.id == dummyCategory.id)

        // type 変更に伴う自動リセットのバインディング検証
        viewModel.type = .income
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.selectedCategoryId == nil)
        #expect(!viewModel.availableCategories.contains(where: { $0.id == dummyCategory.id }))
    }

    @Test("resetSelectedCategory() の直接呼び出しで選択カテゴリがクリアされること")
    func resetSelectedCategory() async throws {
        let (viewModel, _, dummyCategory) = try await makeSUT()
        viewModel.selectedCategoryId = dummyCategory.id

        viewModel.resetSelectedCategory()

        #expect(viewModel.selectedCategoryId == nil)
    }

    // MARK: - 保存・編集・キャンセルのテスト

    @Test("新規追加モードでの save() 成功時に Transaction が追加され画面が閉じること")
    func saveNewSuccess() async throws {
        let (viewModel, _, dummyCategory) = try await makeSUT()
        viewModel.presentInputView()
        viewModel.title = "スーパー"
        viewModel.amount = "2500"
        viewModel.selectedCategoryId = dummyCategory.id

        let success = await viewModel.save()

        #expect(success == true)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isPresentInputView == false)
    }

    @Test("prepareInput() による入力初期化および復元動作の検証")
    func prepareInputBehavior() async throws {
        let (viewModel, _, dummyCategory) = try await makeSUT()
        let now = Date()
        let transaction = try TransactionModel(
            id: UUID(),
            title: "旧タイトル",
            memo: "メモ",
            amount: 1000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )

        // 編集モードでの動作確認
        viewModel.prepareInput(for: transaction)
        #expect(viewModel.isEdit == true)
        #expect(viewModel.title == "旧タイトル")
        #expect(viewModel.amount == "1000")

        // 新規作成モードへのリセット確認
        viewModel.prepareInput(for: nil)
        #expect(viewModel.isEdit == false)
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.amount.isEmpty)
    }

    @Test("編集モードでの復元(restoreForm)と更新(update)の成功")
    func editAndRestoreFormSuccess() async throws {
        let (viewModel, store, dummyCategory) = try await makeSUT()
        let now = Date()
        let transaction = try TransactionModel(
            id: UUID(),
            title: "旧タイトル",
            memo: "メモ",
            amount: 1000,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: dummyCategory.id
        )
        try await store.add(transaction)

        viewModel.presentInputView(for: transaction)
        #expect(viewModel.isEdit == true)
        #expect(viewModel.title == "旧タイトル")

        viewModel.title = "新タイトル"
        let success = await viewModel.save()

        #expect(success == true)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isPresentInputView == false)
    }

    @Test("cancel() および clearError() の検証")
    func cancelAndClearError() async throws {
        let (viewModel, _, _) = try await makeSUT()
        viewModel.presentInputView()
        viewModel.title = "テスト"

        viewModel.cancel()
        #expect(viewModel.isPresentInputView == false)

        let success = await viewModel.save()  // バリデーションエラー発生
        #expect(success == false)
        #expect(viewModel.errorMessage != nil)

        viewModel.clearError()
        #expect(viewModel.errorMessage == nil)
    }
}
