//
//  TransactionInputViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import XCTest
import Combine
@testable import KakeiboApp

@MainActor
final class TransactionInputViewModelTests: XCTestCase {
    private var categoryStore: MockCategoryStore!
    private var transactionStore: MockTransactionStore!
    private var viewModel: TransactionInputViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        categoryStore = MockCategoryStore()
        transactionStore = MockTransactionStore()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        transactionStore = nil
        categoryStore = nil
        try await super.tearDown()
    }

    private func makeViewModel() -> TransactionInputViewModel {
        TransactionInputViewModel(categoryStore: categoryStore, transactionStore: transactionStore)
    }

    private func makeTransaction(
        title: String = "ランチ",
        amount: Double = 1000,
        type: TransactionType = .expense,
        categoryId: UUID = UUID()
    ) -> TransactionModel {
        TransactionModel(
            id: UUID(),
            title: title,
            memo: "",
            amount: amount,
            date: Date(),
            createAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: categoryId
        )
    }

    // フォームに有効な値をセットするヘルパー
    private func fillValidForm(categoryId: UUID) {
        viewModel.title = "ランチ"
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = categoryId
    }

    // MARK: - categories バインディング

    func test_categories_categoryStoreの値が反映される() async throws {
        let categories = [CategoryModel.stub(name: "食費"), CategoryModel.stub(name: "交通費")]
        categoryStore.stubbedCategories = categories
        viewModel = makeViewModel()

        let exp = expectation(description: "categories bound")
        viewModel.$categories
            .first { $0.count == 2 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [exp], timeout: 2.0)
    }

    // MARK: - availableCategories

    func test_availableCategories_selectedTypeに応じてフィルタされる() async throws {
        categoryStore.stubbedCategories = [
            CategoryModel.stub(name: "食費", type: .expense),
            CategoryModel.stub(name: "給与", type: .income),
        ]
        viewModel = makeViewModel()

        let exp = expectation(description: "categories loaded")
        viewModel.$categories
            .first { $0.count == 2 }
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp], timeout: 2.0)

        viewModel.type = .expense
        XCTAssertEqual(viewModel.availableCategories.count, 1)
        XCTAssertEqual(viewModel.availableCategories.first?.name, "食費")

        viewModel.type = .income
        XCTAssertEqual(viewModel.availableCategories.count, 1)
        XCTAssertEqual(viewModel.availableCategories.first?.name, "給与")
    }

    // MARK: - selectedCategory

    func test_selectedCategory_selectedCategoryIdに対応するカテゴリが返る() async throws {
        let category = CategoryModel.stub(name: "食費")
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()

        let exp = expectation(description: "categories loaded")
        viewModel.$categories.first { $0.count == 1 }.sink { _ in exp.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp], timeout: 2.0)

        viewModel.selectedCategoryId = category.id

        XCTAssertEqual(viewModel.selectedCategory?.id, category.id)
    }

    func test_selectedCategory_selectedCategoryIdがnilのときnilが返る() {
        viewModel = makeViewModel()
        viewModel.selectedCategoryId = nil

        XCTAssertNil(viewModel.selectedCategory)
    }

    // MARK: - type変更でselectedCategoryIdがリセットされる

    func test_type変更でselectedCategoryIdがリセットされる() async throws {
        let category = CategoryModel.stub(name: "食費", type: .expense)
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()

        let exp = expectation(description: "categories loaded")
        viewModel.$categories.first { $0.count == 1 }.sink { _ in exp.fulfill() }
            .store(in: &cancellables)
        await fulfillment(of: [exp], timeout: 2.0)

        viewModel.selectedCategoryId = category.id
        XCTAssertNotNil(viewModel.selectedCategoryId)

        viewModel.type = .income

        XCTAssertNil(viewModel.selectedCategoryId)
    }

    // MARK: - presentInputView

    func test_presentInputView_新規作成時にフォームがリセットされisPresentInputViewがtrueになる() {
        viewModel = makeViewModel()
        viewModel.title = "既存タイトル"

        viewModel.presentInputView()

        XCTAssertTrue(viewModel.isPresentInputView)
        XCTAssertFalse(viewModel.isEdit)
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.amount, "")
        XCTAssertNil(viewModel.selectedCategoryId)
    }

    func test_presentInputView_編集時にフォームが復元されisEditがtrueになる() {
        let categoryId = UUID()
        let transaction = makeTransaction(title: "ランチ", amount: 1500, categoryId: categoryId)
        viewModel = makeViewModel()

        viewModel.presentInputView(for: transaction)

        XCTAssertTrue(viewModel.isPresentInputView)
        XCTAssertTrue(viewModel.isEdit)
        XCTAssertEqual(viewModel.title, "ランチ")
        XCTAssertEqual(viewModel.amount, "1500")
        XCTAssertEqual(viewModel.selectedCategoryId, categoryId)
    }

    // MARK: - isFormValid / バリデーション

    func test_isFormValid_全フィールドが正しいときtrueが返る() {
        viewModel = makeViewModel()
        viewModel.title = "ランチ"
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = UUID()

        XCTAssertTrue(viewModel.isFormValid)
    }

    func test_isFormValid_titleが空のときfalseが返る() {
        viewModel = makeViewModel()
        viewModel.title = ""
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = UUID()

        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_isFormValid_titleが空白のみのときfalseが返る() {
        viewModel = makeViewModel()
        viewModel.title = "   "
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = UUID()

        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_isFormValid_amountが0のときfalseが返る() {
        viewModel = makeViewModel()
        viewModel.title = "ランチ"
        viewModel.amount = "0"
        viewModel.selectedCategoryId = UUID()

        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_isFormValid_amountが負のときfalseが返る() {
        viewModel = makeViewModel()
        viewModel.title = "ランチ"
        viewModel.amount = "-100"
        viewModel.selectedCategoryId = UUID()

        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_isFormValid_amountが数値以外のときfalseが返る() {
        viewModel = makeViewModel()
        viewModel.title = "ランチ"
        viewModel.amount = "abc"
        viewModel.selectedCategoryId = UUID()

        XCTAssertFalse(viewModel.isFormValid)
    }

    func test_isFormValid_categoryIdがnilのときfalseが返る() {
        viewModel = makeViewModel()
        viewModel.title = "ランチ"
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = nil

        XCTAssertFalse(viewModel.isFormValid)
    }

    // MARK: - save 正常系

    func test_save_新規作成でaddが呼ばれisPresentInputViewがfalseになる() async throws {
        let category = CategoryModel.stub()
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()
        viewModel.presentInputView()
        fillValidForm(categoryId: category.id)

        await viewModel.save()

        XCTAssertEqual(transactionStore.addCallCount, 1)
        XCTAssertFalse(viewModel.isPresentInputView)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_save_編集時にupdateが呼ばれisPresentInputViewがfalseになる() async throws {
        let category = CategoryModel.stub()
        categoryStore.stubbedCategories = [category]
        let transaction = makeTransaction(categoryId: category.id)
        transactionStore.stubbedTransactions = [transaction]
        viewModel = makeViewModel()
        viewModel.presentInputView(for: transaction)
        viewModel.title = "更新後タイトル"

        await viewModel.save()

        XCTAssertEqual(transactionStore.updateCallCount, 1)
        XCTAssertFalse(viewModel.isPresentInputView)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_save_成功後にフォームがリセットされる() async throws {
        let category = CategoryModel.stub()
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()
        viewModel.presentInputView()
        fillValidForm(categoryId: category.id)

        await viewModel.save()

        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.amount, "")
        XCTAssertNil(viewModel.selectedCategoryId)
    }

    func test_save_isLoadingがtrueからfalseに変化する() async throws {
        let category = CategoryModel.stub()
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()
        viewModel.presentInputView()
        fillValidForm(categoryId: category.id)
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        await viewModel.save()

        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertEqual(loadingStates.last, false)
    }

    // MARK: - save バリデーションエラー

    func test_save_titleが空のときerrorMessageがセットされaddが呼ばれない() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView()
        viewModel.title = ""
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = UUID()

        await viewModel.save()

        XCTAssertEqual(transactionStore.addCallCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isPresentInputView)
    }

    func test_save_amountが無効のときerrorMessageがセットされる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView()
        viewModel.title = "ランチ"
        viewModel.amount = "abc"
        viewModel.selectedCategoryId = UUID()

        await viewModel.save()

        XCTAssertEqual(transactionStore.addCallCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func test_save_categoryが未選択のときerrorMessageがセットされる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView()
        viewModel.title = "ランチ"
        viewModel.amount = "1000"
        viewModel.selectedCategoryId = nil

        await viewModel.save()

        XCTAssertEqual(transactionStore.addCallCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - save 異常系

    func test_save_addエラー時にerrorMessageがセットされisPresentInputViewがtrueのまま() async throws {
        let category = CategoryModel.stub()
        categoryStore.stubbedCategories = [category]
        transactionStore.addError = CustomError.transactionNotFoundError
        // Note: MockTransactionStore に addError を追加する必要があります
        viewModel = makeViewModel()
        viewModel.presentInputView()
        fillValidForm(categoryId: category.id)

        await viewModel.save()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("保存に失敗しました") == true)
        XCTAssertTrue(viewModel.isPresentInputView)
    }

    // MARK: - cancel

    func test_cancel_isPresentInputViewがfalseになりフォームがリセットされる() {
        viewModel = makeViewModel()
        viewModel.presentInputView()
        viewModel.title = "ランチ"

        viewModel.cancel()

        XCTAssertFalse(viewModel.isPresentInputView)
        XCTAssertEqual(viewModel.title, "")
    }

    // MARK: - clearError

    func test_clearError_errorMessageがnilになる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView()
        viewModel.title = ""
        await viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - resetSelectedCategory

    func test_resetSelectedCategory_selectedCategoryIdがnilになる() {
        viewModel = makeViewModel()
        viewModel.selectedCategoryId = UUID()

        viewModel.resetSelectedCategory()

        XCTAssertNil(viewModel.selectedCategoryId)
    }
}
