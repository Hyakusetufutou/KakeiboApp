//
//  ModelTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/08/15
//
//

import Testing
import SwiftUI
import CoreData
@testable import KakeiboApp

// MARK: - 1. CategoryColor & CategoryModel Tests

@Suite("CategoryColor のテスト")
struct CategoryColorTests {

    @Test("SwiftUI.Color から CategoryColor への変換が正しく機能すること")
    func initFromColor() {
        #expect(CategoryColor(color: .red) == .red)
        #expect(CategoryColor(color: .orange) == .orange)
        #expect(CategoryColor(color: .yellow) == .yellow)
        #expect(CategoryColor(color: .green) == .green)
        #expect(CategoryColor(color: .mint) == .mint)
        #expect(CategoryColor(color: .teal) == .teal)
        #expect(CategoryColor(color: .blue) == .blue)
        #expect(CategoryColor(color: .indigo) == .indigo)
        #expect(CategoryColor(color: .purple) == .purple)
        #expect(CategoryColor(color: .pink) == .pink)
        #expect(CategoryColor(color: .brown) == .brown)
        #expect(CategoryColor(color: .gray) == .gray)

        // 未定義カラーのデフォルト値フォールバック検証
        #expect(CategoryColor(color: .clear) == .blue)
    }

    @Test("CategoryColor から SwiftUI.Color への変換が取得できること")
    func colorProperty() {
        #expect(CategoryColor.red.color == .red)
        #expect(CategoryColor.blue.color == .blue)
    }
}

@Suite("CategoryModel のテスト")
struct CategoryModelTests {

    @Test("正常なパラメータで CategoryModel が正常に初期化できること")
    func validInitialization() throws {
        let id = UUID()
        let category = try CategoryModel(
            id: id,
            name: "食費",
            color: .orange,
            type: .expense,
            isDefault: false
        )

        #expect(category.id == id)
        #expect(category.name == "食費")
        #expect(category.color == .orange)
        #expect(category.type == .expense)
        #expect(category.isDefault == false)
    }

    @Test("名前が空文文字または空白のみの場合に CustomError.invalidData がスローされること")
    func emptyNameThrowsError() {
        // 空文字
        #expect(throws: CustomError.invalidData) {
            try CategoryModel(name: "", color: .red, type: .expense, isDefault: false)
        }

        // 空白のみ
        #expect(throws: CustomError.invalidData) {
            try CategoryModel(name: "   \n\t ", color: .red, type: .expense, isDefault: false)
        }
    }

    @Test("デフォルトカテゴリ定義 (CategoryModel.defaults) が正常に取得できること")
    func defaultsProperty() {
        let defaults = CategoryModel.defaults
        #expect(defaults.count == 7)
        #expect(defaults.filter { $0.type == .expense }.count == 5)
        #expect(defaults.filter { $0.type == .income }.count == 2)
        #expect(defaults.allSatisfy { $0.isDefault == true })
    }
}

// MARK: - 2. TransactionType & TransactionModel Tests

@Suite("TransactionType のテスト")
struct TransactionTypeTests {

    @Test("rawValue / Raw Representable が正しく定義されていること")
    func rawValues() {
        #expect(TransactionType.income.rawValue == "収入")
        #expect(TransactionType.expense.rawValue == "支出")
        #expect(TransactionType.income.id == .income)
    }

    @Test("各 TransactionType に応じた imageName が返されること")
    func imageNames() {
        #expect(TransactionType.income.imageName == "tray.and.arrow.down.fill")
        #expect(TransactionType.expense.imageName == "tray.and.arrow.up.fill")
    }
}

@Suite("TransactionModel のテスト")
struct TransactionModelTests {

    @Test("正常な値で TransactionModel が作成できること")
    func validInitialization() throws {
        let now = Date()
        let categoryId = UUID()
        let transaction = try TransactionModel(
            title: "ランチ",
            memo: "日替わり定食",
            amount: 950,
            date: now,
            createdAt: now,
            updatedAt: now,
            type: .expense,
            categoryId: categoryId
        )

        #expect(transaction.title == "ランチ")
        #expect(transaction.memo == "日替わり定食")
        #expect(transaction.amount == 950)
        #expect(transaction.type == .expense)
        #expect(transaction.categoryId == categoryId)
    }

    @Test("タイトルが空または空白のみの場合に CustomError.invalidData がスローされること")
    func emptyTitleThrowsError() {
        let now = Date()
        #expect(throws: CustomError.invalidData) {
            try TransactionModel(
                title: "   ",
                memo: "",
                amount: 100,
                date: now,
                createdAt: now,
                updatedAt: now,
                type: .expense,
                categoryId: UUID()
            )
        }
    }

    @Test("金額 (amount) が負の値の場合に CustomError.invalidData がスローされること")
    func negativeAmountThrowsError() {
        let now = Date()
        #expect(throws: CustomError.invalidData) {
            try TransactionModel(
                title: "テスト",
                memo: "",
                amount: -1,
                date: now,
                createdAt: now,
                updatedAt: now,
                type: .expense,
                categoryId: UUID()
            )
        }
    }
}

// MARK: - 3. DateRange Tests

@Suite("DateRange のテスト")
struct DateRangeTests {

    @Test("start <= end の場合、そのまま初期化されること")
    func validOrderInit() {
        let start = Date(timeIntervalSince1970: 1000)
        let end = Date(timeIntervalSince1970: 2000)
        let range = DateRange(start: start, end: end)

        #expect(range.start == start)
        #expect(range.end == end)
        #expect(range.startDate == start)
    }

    @Test("start > end の場合、自動的に入れ替えられて初期化されること")
    func invertedOrderInit() {
        let start = Date(timeIntervalSince1970: 2000)
        let end = Date(timeIntervalSince1970: 1000)
        let range = DateRange(start: start, end: end)

        #expect(range.start == end)
        #expect(range.end == start)
    }

    @Test("endDate プロパティが end に1日（24時間）足した日付を返すこと")
    func endDateCalculation() {
        let start = Date(timeIntervalSince1970: 0)
        let end = Date(timeIntervalSince1970: 0)
        let range = DateRange(start: start, end: end)

        let expectedEndDate = Calendar.current.date(byAdding: .init(day: 1), to: end)!
        #expect(range.endDate == expectedEndDate)
    }

    @Test("contains メソッドの範囲判定が正しいこと（startDate 以上、endDate 未満）")
    func containsValidation() {
        let calendar = Calendar.current
        let start = calendar.date(from: DateComponents(year: 2026, month: 2, day: 1))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 2, day: 28))!
        let range = DateRange(start: start, end: end)

        // range.endDate は 2026/03/01 00:00:00
        let endDate = range.endDate

        // 境界値テスト
        #expect(range.contains(start) == true)  // 開始日当日の開始時刻 (含む)
        #expect(range.contains(end) == true)  // 終了日当日の開始時刻 (含む)
        #expect(range.contains(endDate.addingTimeInterval(-1)) == true)  // endDate 直前 23:59:59 (含む)
        #expect(range.contains(endDate) == false)  // endDate ちょうど (含まない)
        #expect(range.contains(start.addingTimeInterval(-1)) == false)  // start 直前 (含まない)
    }

    @Test("withStart / withEnd イミュータブル変更メソッドの検証")
    func immutabilityModifiers() {
        let t1 = Date(timeIntervalSince1970: 1000)
        let t2 = Date(timeIntervalSince1970: 2000)
        let t3 = Date(timeIntervalSince1970: 3000)

        let initialRange = DateRange(start: t1, end: t2)

        let newStartRange = initialRange.withStart(t1)
        #expect(newStartRange == DateRange(start: t1, end: t2))

        let newEndRange = initialRange.withEnd(t3)
        #expect(newEndRange == DateRange(start: t1, end: t3))
    }

    @Test("Equatable の一致判定が機能すること")
    func equatableConformance() {
        let t1 = Date(timeIntervalSince1970: 1000)
        let t2 = Date(timeIntervalSince1970: 2000)

        let range1 = DateRange(start: t1, end: t2)
        let range2 = DateRange(start: t1, end: t2)
        let range3 = DateRange(start: t1, end: t1)

        #expect(range1 == range2)
        #expect(range1 != range3)
    }
}

// MARK: - 4. Error & ErrorMapper Tests

@Suite("Error & ErrorMapper のテスト")
struct ErrorTests {

    @Test("CustomError の errorDescription メッセージ表示検証")
    func customErrorDescriptions() {
        #expect(CustomError.categoryNotFoundError.errorDescription == "カテゴリが見つかりません")
        #expect(CustomError.transactionNotFoundError.errorDescription == "取引が見つかりません")
        #expect(CustomError.saveError.errorDescription == "保存に失敗しました")
        #expect(CustomError.fetchError("DBエラー").errorDescription == "取得に失敗しました: DBエラー")
        #expect(CustomError.invalidData.errorDescription == "不正なデータです")
        #expect(CustomError.cannotDeletedefaultCategory.errorDescription == "デフォルトカテゴリのため削除できません")
    }

    @Test("CategoryMapperError & TransactionMapperError の errorDescription メッセージ表示検証")
    func mapperErrorDescriptions() {
        #expect(CategoryMapperError.invalidColor.errorDescription == "カテゴリの色が無効です")
        #expect(CategoryMapperError.invalidType.errorDescription == "カテゴリの種類が無効です")
        #expect(TransactionMapperError.invalidType.errorDescription == "Transactionの種別が無効です")
    }

    @Test("ErrorMapper.message(for:) が localizedDescription を正しく返却すること")
    func errorMapper() {
        let err: Error = CustomError.saveError
        let message = ErrorMapper.message(for: err)
        #expect(message == "保存に失敗しました")
    }
}
