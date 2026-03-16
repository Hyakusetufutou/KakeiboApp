//
//  CategoryInputViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import XCTest
import Combine
import SwiftUI
@testable import KakeiboApp

@MainActor
final class CategoryInputViewModelTests: XCTestCase {
    private var categoryStore: MockCategoryStore!
    private var viewModel: CategoryInputViewModel!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() async throws {
        try await super.setUp()
        categoryStore = MockCategoryStore()
        cancellables = []
    }

    override func tearDown() async throws {
        cancellables = nil
        viewModel = nil
        categoryStore = nil
        try await super.tearDown()
    }

    private func makeViewModel() -> CategoryInputViewModel {
        CategoryInputViewModel(categoryStore: categoryStore)
    }

    // MARK: - presentInputView

    func test_presentInputView_新規作成時にフォームがリセットされisPresentInputViewがtrueになる() {
        viewModel = makeViewModel()
        viewModel.name = "既存の名前"

        viewModel.presentInputView(type: .expense)

        XCTAssertTrue(viewModel.isPresentInputView)
        XCTAssertFalse(viewModel.isEdit)
        XCTAssertEqual(viewModel.name, "")
        XCTAssertEqual(viewModel.type, .expense)
    }

    func test_presentInputView_編集時にフォームが復元されisEditがtrueになる() {
        viewModel = makeViewModel()
        let category = CategoryModel.stub(name: "食費", type: .expense)

        viewModel.presentInputView(type: .expense, categoryItem: category)

        XCTAssertTrue(viewModel.isPresentInputView)
        XCTAssertTrue(viewModel.isEdit)
        XCTAssertEqual(viewModel.name, "食費")
        XCTAssertEqual(viewModel.id, category.id)
        XCTAssertEqual(viewModel.type, .expense)
    }

    func test_presentInputView_収入タイプが正しくセットされる() {
        viewModel = makeViewModel()

        viewModel.presentInputView(type: .income)

        XCTAssertEqual(viewModel.type, .income)
    }

    // MARK: - save 正常系

    func test_save_新規作成でaddが呼ばれisPresentInputViewがfalseになる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "娯楽"

        await viewModel.save()

        XCTAssertEqual(categoryStore.addCallCount, 1)
        XCTAssertFalse(viewModel.isPresentInputView)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_save_編集時にupdateが呼ばれisPresentInputViewがfalseになる() async throws {
        let category = CategoryModel.stub(name: "食費")
        categoryStore.stubbedCategories = [category]
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense, categoryItem: category)
        viewModel.name = "外食費"

        await viewModel.save()

        XCTAssertEqual(categoryStore.updateCallCount, 1)
        XCTAssertFalse(viewModel.isPresentInputView)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_save_成功後にフォームがリセットされる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "娯楽"

        await viewModel.save()

        XCTAssertEqual(viewModel.name, "")
        XCTAssertFalse(viewModel.isPresentInputView)
    }

    // MARK: - save バリデーション

    func test_save_名前が空のときerrorMessageがセットされaddが呼ばれない() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = ""

        await viewModel.save()

        XCTAssertEqual(categoryStore.addCallCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isPresentInputView)  // 閉じない
    }

    func test_save_名前が空白のみのときerrorMessageがセットされる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "   "

        await viewModel.save()

        XCTAssertEqual(categoryStore.addCallCount, 0)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    // MARK: - save 異常系

    func test_save_addエラー時にerrorMessageがセットされisPresentInputViewがtrueのまま() async throws {
        categoryStore.addError = CustomError.categoryNotFoundError
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "娯楽"

        await viewModel.save()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage?.contains("保存に失敗しました") == true)
        XCTAssertTrue(viewModel.isPresentInputView)  // エラー時は閉じない
    }

    func test_save_updateエラー時にerrorMessageがセットされisPresentInputViewがtrueのまま() async throws {
        let category = CategoryModel.stub(name: "食費")
        categoryStore.stubbedCategories = [category]
        categoryStore.updateError = CustomError.categoryNotFoundError
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense, categoryItem: category)
        viewModel.name = "外食費"

        await viewModel.save()

        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.isPresentInputView)
    }

    func test_save_isLoadingがtrueからfalseに変化する() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "娯楽"
        var loadingStates: [Bool] = []

        viewModel.$isLoading
            .sink { loadingStates.append($0) }
            .store(in: &cancellables)

        await viewModel.save()

        XCTAssertTrue(loadingStates.contains(true))
        XCTAssertEqual(loadingStates.last, false)
    }

    // MARK: - cancel

    func test_cancel_isPresentInputViewがfalseになりフォームがリセットされる() {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "娯楽"

        viewModel.cancel()

        XCTAssertFalse(viewModel.isPresentInputView)
        XCTAssertEqual(viewModel.name, "")
    }

    // MARK: - clearError

    func test_clearError_errorMessageがnilになる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = ""
        await viewModel.save()
        XCTAssertNotNil(viewModel.errorMessage)

        viewModel.clearError()

        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - フォームリセット

    func test_save後_新たにpresentInputViewを呼ぶとフォームがリセットされる() async throws {
        viewModel = makeViewModel()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "娯楽"
        await viewModel.save()

        viewModel.presentInputView(type: .income)

        XCTAssertEqual(viewModel.name, "")
        XCTAssertFalse(viewModel.isEdit)
        XCTAssertEqual(viewModel.type, .income)
    }
}
