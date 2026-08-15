//
//  CategoryInputViewModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/16
//
//

import Testing
import CoreData
@testable import KakeiboApp

@MainActor
@Suite("CategoryInputViewModel のテスト")
struct CategoryInputViewModelTests {

    private func makeSUT(autoLoad: Bool = false) -> (CategoryInputViewModel, CategoryStore) {
        let container = PersistenceController(inMemory: true).container
        let repository = CategoryRepository(container: container)
        let store = CategoryStore(repository: repository, autoLoad: autoLoad)
        let viewModel = CategoryInputViewModel(categoryStore: store)
        return (viewModel, store)
    }

    // MARK: - 画面表示・初期化のテスト

    @Test("presentInputView で新規作成と編集モードが切り替わること")
    func presentInputView() {
        let (viewModel, _) = makeSUT()
        let category = CategoryModel(
            id: UUID(),
            name: "趣味",
            color: .purple,
            type: .expense,
            isDefault: false
        )

        // 新規作成時
        viewModel.presentInputView(type: .income, categoryItem: nil)
        #expect(viewModel.isPresentInputView == true)
        #expect(viewModel.isEdit == false)
        #expect(viewModel.name.isEmpty)
        #expect(viewModel.type == .income)

        // 編集時
        viewModel.presentInputView(type: .expense, categoryItem: category)
        #expect(viewModel.isPresentInputView == true)
        #expect(viewModel.isEdit == true)
        #expect(viewModel.name == "趣味")
        #expect(viewModel.color == .purple)
        #expect(viewModel.type == .expense)
    }

    // MARK: - 保存ロジック・バリデーションのテスト

    @Test("名前が空（または空白のみ）の場合、save() でエラーメッセージが設定されること")
    func saveWithInvalidName() async {
        let (viewModel, _) = makeSUT()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "   "

        await viewModel.save()

        #expect(viewModel.errorMessage == "カテゴリ名を入力してください")
        #expect(viewModel.isPresentInputView == true)
    }

    @Test("新規追加モードでの save() 成功時にストアへ追加され画面が閉じること")
    func saveNewCategorySuccess() async throws {
        let (viewModel, store) = makeSUT()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "日用品"
        viewModel.color = .green
        let targetId = viewModel.id

        await viewModel.save()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isPresentInputView == false)
        #expect(store.find(id: targetId) != nil)
    }

    @Test("編集モードでの save() 成功時にカテゴリが更新されること")
    func saveUpdatedCategorySuccess() async throws {
        let (viewModel, store) = makeSUT()
        let category = CategoryModel(
            id: UUID(),
            name: "外食",
            color: .orange,
            type: .expense,
            isDefault: false
        )
        try await store.add(category)

        viewModel.presentInputView(type: .expense, categoryItem: category)
        viewModel.name = "外食・カフェ"

        await viewModel.save()

        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.isPresentInputView == false)
        #expect(store.find(id: category.id)?.name == "外食・カフェ")
    }

    // MARK: - ヘルパー・キャンセルのテスト

    @Test("cancel() 呼出し時に画面が閉じフォームがリセットされること")
    func cancel() {
        let (viewModel, _) = makeSUT()
        viewModel.presentInputView(type: .expense)
        viewModel.name = "一時入力"

        viewModel.cancel()

        #expect(viewModel.isPresentInputView == false)
        #expect(viewModel.name.isEmpty)
    }

    @Test("clearError() 呼出し時に errorMessage が nil になること")
    func clearError() async {
        let (viewModel, _) = makeSUT()
        viewModel.presentInputView(type: .expense)
        await viewModel.save()  // バリデーションエラー発生
        #expect(viewModel.errorMessage != nil)

        viewModel.clearError()

        #expect(viewModel.errorMessage == nil)
    }
}
