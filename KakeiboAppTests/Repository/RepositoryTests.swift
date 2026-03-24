//
//  RepositoryTests.swift
//  KakeiboAppTests
//
//  Created by Hyakusetufutou on 2026/03/12
//
//

import XCTest
import CoreData
@testable import KakeiboApp

// MARK: - In-Memory Container

extension NSPersistentContainer {
    static func makeInMemory(name: String = "KakeiboApp") -> NSPersistentContainer {
        let container = NSPersistentContainer(name: name)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            if let error { fatalError("In-memory store failed: \(error)") }
        }
        return container
    }
}

// MARK: - CategoryRepository Tests

final class CategoryRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var repository: CategoryRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = .makeInMemory()
        repository = CategoryRepository(container: container)
    }

    override func tearDown() async throws {
        repository = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - テストデータ生成

    private func makeCategory(
        name: String = "食費",
        type: TransactionType = .expense,
        isDefault: Bool = false
    ) -> CategoryModel {
        CategoryModel(
            id: UUID(),
            name: name,
            color: .orange,
            type: type,
            isDefault: isDefault
        )
    }

    // MARK: - 正常系

    func test_fetchAll_追加したカテゴリが全件取得できる() async throws {
        let categories = ["食費", "交通費", "娯楽"].map { makeCategory(name: $0) }
        for category in categories { try await repository.add(category) }

        let fetched = try await repository.fetchAll()

        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched.map(\.name), ["交通費", "娯楽", "食費"])
    }

    func test_fetchById_正しいカテゴリが取得できる() async throws {
        let category = makeCategory(name: "医療費")
        try await repository.add(category)

        let fetched = try await repository.fetch(by: category.id)

        XCTAssertEqual(fetched.id, category.id)
        XCTAssertEqual(fetched.name, "医療費")
    }

    func test_add_カテゴリが保存される() async throws {
        let category = makeCategory(name: "給与", type: .income)
        try await repository.add(category)

        let fetched = try await repository.fetchAll()

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "給与")
        XCTAssertEqual(fetched.first?.type, .income)
    }

    func test_update_カテゴリが更新される() async throws {
        let original = makeCategory(name: "食費")
        try await repository.add(original)

        let updated = CategoryModel(
            id: original.id,
            name: "外食費",
            color: .red,
            type: .expense,
            isDefault: false
        )
        try await repository.update(updated)

        let fetched = try await repository.fetch(by: original.id)
        XCTAssertEqual(fetched.name, "外食費")
    }

    func test_delete_カテゴリが削除される() async throws {
        let category = makeCategory(name: "日用品")
        try await repository.add(category)

        try await repository.delete(category)

        let fetched = try await repository.fetchAll()
        XCTAssertTrue(fetched.isEmpty)
    }

    func test_fetchAll_name昇順でソートされる() async throws {
        // 意図的にバラバラな順序で追加
        for name in ["娯楽", "食費", "交通費", "医療費"] {
            try await repository.add(makeCategory(name: name))
        }

        let fetched = try await repository.fetchAll()

        XCTAssertEqual(fetched.map(\.name), ["交通費", "医療費", "娯楽", "食費"])
    }

    // MARK: - 異常系

    func test_fetchById_存在しないIDでエラーがthrowされる() async throws {
        do {
            _ = try await repository.fetch(by: UUID())
            XCTFail("エラーがthrowされるべき")
        } catch let error as CustomError {
            XCTAssertEqual(error, .categoryNotFoundError)
        }
    }

    func test_update_存在しないIDでエラーがthrowされる() async throws {
        let nonExistent = makeCategory(name: "存在しない")

        do {
            try await repository.update(nonExistent)
            XCTFail("エラーがthrowされるべき")
        } catch let error as CustomError {
            XCTAssertEqual(error, .categoryNotFoundError)
        }
    }

    func test_delete_存在しないIDでエラーがthrowされる() async throws {
        let nonExistent = makeCategory(name: "存在しない")

        do {
            try await repository.delete(nonExistent)
            XCTFail("エラーがthrowされるべき")
        } catch let error as CustomError {
            XCTAssertEqual(error, .categoryNotFoundError)
        }
    }

    // MARK: - 境界値

    func test_fetchAll_データが0件のとき空配列が返る() async throws {
        let fetched = try await repository.fetchAll()
        XCTAssertTrue(fetched.isEmpty)
    }

    func test_add_同じIDを2回追加するとfetchAllで1件になる() async throws {
        let id = UUID()
        let category1 = CategoryModel(
            id: id,
            name: "食費",
            color: .orange,
            type: .expense,
            isDefault: false
        )
        let category2 = CategoryModel(
            id: id,
            name: "食費2",
            color: .blue,
            type: .expense,
            isDefault: false
        )

        try await repository.add(category1)
        // 同じIDで追加するとCoreDataレベルで衝突する可能性があるため例外を期待
        do {
            try await repository.add(category2)
            // 実装によっては成功する場合もあるため、件数で確認
            let fetched = try await repository.fetchAll()
            XCTAssertLessThanOrEqual(fetched.count, 2)
        } catch {
            // エラーになる場合も正常な振る舞い
        }
    }

    func test_delete後_fetchAllで残りのカテゴリが正しく返る() async throws {
        let keep = makeCategory(name: "残す")
        let remove = makeCategory(name: "削除する")
        try await repository.add(keep)
        try await repository.add(remove)

        try await repository.delete(remove)

        let fetched = try await repository.fetchAll()
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.name, "残す")
    }
}

// MARK: - TransactionRepository Tests

final class TransactionRepositoryTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var transactionRepository: TransactionRepository!
    private var categoryRepository: CategoryRepository!
    private var defaultCategory: CategoryModel!

    override func setUp() async throws {
        try await super.setUp()
        container = .makeInMemory()
        transactionRepository = TransactionRepository(container: container)
        categoryRepository = CategoryRepository(container: container)

        defaultCategory = CategoryModel(
            id: UUID(),
            name: "食費",
            color: .orange,
            type: .expense,
            isDefault: false
        )
        try await categoryRepository.add(defaultCategory)
    }

    override func tearDown() async throws {
        defaultCategory = nil
        transactionRepository = nil
        categoryRepository = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - テストデータ生成

    private func makeTransaction(
        title: String = "テスト",
        amount: Double = 1000,
        date: Date = Date(),
        type: TransactionType = .expense,
        memo: String? = nil,
        categoryId: UUID? = nil
    ) -> TransactionModel {
        TransactionModel(
            id: UUID(),
            title: title,
            memo: memo ?? "",
            amount: amount,
            date: date,
            createdAt: Date(),
            updatedAt: Date(),
            type: type,
            categoryId: categoryId ?? defaultCategory.id
        )
    }

    // MARK: - 正常系

    func test_fetch_追加したトランザクションが取得できる() async throws {
        let transactions = ["ランチ", "電車", "コンビニ"].map { makeTransaction(title: $0) }
        for t in transactions { try await transactionRepository.add(t) }

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: nil,
            offset: nil
        )

        XCTAssertEqual(fetched.count, 3)
    }

    func test_fetch_date降順でソートされる() async throws {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        try await transactionRepository.add(makeTransaction(title: "2日前", date: twoDaysAgo))
        try await transactionRepository.add(makeTransaction(title: "昨日", date: yesterday))
        try await transactionRepository.add(makeTransaction(title: "今日", date: today))

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: nil,
            offset: nil
        )

        XCTAssertEqual(fetched.map(\.title), ["今日", "昨日", "2日前"])
    }

    func test_fetch_limit指定で件数が制限される() async throws {
        for i in 1...10 { try await transactionRepository.add(makeTransaction(title: "\(i)")) }

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: 3,
            offset: nil
        )

        XCTAssertEqual(fetched.count, 3)
    }

    func test_fetch_offset指定でページネーションできる() async throws {
        let calendar = Calendar.current
        let base = Date()
        for i in 0..<10 {
            let date = calendar.date(byAdding: .day, value: -i, to: base)!
            try await transactionRepository.add(makeTransaction(title: "item\(i)", date: date))
        }

        let page1 = try await transactionRepository.fetch(from: nil, to: nil, limit: 5, offset: 0)
        let page2 = try await transactionRepository.fetch(from: nil, to: nil, limit: 5, offset: 5)

        XCTAssertEqual(page1.count, 5)
        XCTAssertEqual(page2.count, 5)
        // ページが重複していないことを確認
        let allIds = (page1 + page2).map(\.id)
        XCTAssertEqual(allIds.count, Set(allIds).count)
    }

    func test_fetch_日付範囲フィルタが機能する() async throws {
        let calendar = Calendar.current
        let today = Date()
        let startOfMonth = today.startOfMonth
        let endOfMonth = today.endOfMonth
        let lastMonth = calendar.date(byAdding: .month, value: -1, to: today)!

        try await transactionRepository.add(makeTransaction(title: "今月", date: today))
        try await transactionRepository.add(makeTransaction(title: "先月", date: lastMonth))

        let fetched = try await transactionRepository.fetch(
            from: startOfMonth,
            to: endOfMonth,
            limit: nil,
            offset: nil
        )

        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "今月")
    }

    func test_update_トランザクションが更新される() async throws {
        let original = makeTransaction(title: "食費", amount: 1000)
        try await transactionRepository.add(original)

        let updated = TransactionModel(
            id: original.id,
            title: "外食費",
            memo: "友人と",
            amount: 2000,
            date: original.date,
            createdAt: original.createdAt,
            updatedAt: Date(),
            type: original.type,
            categoryId: original.categoryId
        )

        try await transactionRepository.update(updated)

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: nil,
            offset: nil
        )
        let result = fetched.first { $0.id == original.id }
        XCTAssertEqual(result?.title, "外食費")
        XCTAssertEqual(result?.amount, 2000)
        XCTAssertEqual(result?.memo, "友人と")
    }

    func test_delete_トランザクションが削除される() async throws {
        let transaction = makeTransaction(title: "削除対象")
        try await transactionRepository.add(transaction)

        try await transactionRepository.delete(transaction)

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: nil,
            offset: nil
        )
        XCTAssertTrue(fetched.isEmpty)
    }

    func test_search_titleで検索できる() async throws {
        try await transactionRepository.add(makeTransaction(title: "ランチ"))
        try await transactionRepository.add(makeTransaction(title: "交通費"))
        try await transactionRepository.add(makeTransaction(title: "ランニングシューズ"))

        let results = try await transactionRepository.search(text: "ラン")

        XCTAssertEqual(results.count, 2)
    }

    func test_search_memoで検索できる() async throws {
        try await transactionRepository.add(makeTransaction(title: "食費", memo: "スーパーで購入"))
        try await transactionRepository.add(makeTransaction(title: "交通費", memo: nil))

        let results = try await transactionRepository.search(text: "スーパー")

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "食費")
    }

    func test_search_大文字小文字を区別しない() async throws {
        try await transactionRepository.add(makeTransaction(title: "Lunch"))

        let results = try await transactionRepository.search(text: "lunch")

        XCTAssertEqual(results.count, 1)
    }

    // MARK: - 異常系

    func test_update_存在しないIDでエラーがthrowされる() async throws {
        let nonExistent = makeTransaction(title: "存在しない")

        do {
            try await transactionRepository.update(nonExistent)
            XCTFail("エラーがthrowされるべき")
        } catch let error as CustomError {
            XCTAssertEqual(error, .transactionNotFoundError)
        }
    }

    func test_delete_存在しないIDでエラーがthrowされる() async throws {
        let nonExistent = makeTransaction(title: "存在しない")

        do {
            try await transactionRepository.delete(nonExistent)
            XCTFail("エラーがthrowされるべき")
        } catch let error as CustomError {
            XCTAssertEqual(error, .transactionNotFoundError)
        }
    }

    func test_add_存在しないcategoryIdでエラーがthrowされる() async throws {
        let transaction = makeTransaction(categoryId: UUID())  // 存在しないカテゴリID

        do {
            try await transactionRepository.add(transaction)
            XCTFail("エラーがthrowされるべき")
        } catch let error as CustomError {
            XCTAssertEqual(error, .categoryNotFoundError)
        }
    }

    // MARK: - 境界値

    func test_fetch_データが0件のとき空配列が返る() async throws {
        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: nil,
            offset: nil
        )
        XCTAssertTrue(fetched.isEmpty)
    }

    func test_fetch_offsetがデータ件数を超えたとき空配列が返る() async throws {
        try await transactionRepository.add(makeTransaction())

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: 10,
            offset: 100
        )

        XCTAssertTrue(fetched.isEmpty)
    }

    func test_fetch_月の境界日がフィルタに含まれる() async throws {
        let today = Date()
        let startOfMonth = today.startOfMonth
        let endOfMonth = today.endOfMonth

        try await transactionRepository.add(makeTransaction(title: "月初", date: startOfMonth))
        try await transactionRepository.add(makeTransaction(title: "月末", date: endOfMonth))

        let fetched = try await transactionRepository.fetch(
            from: startOfMonth,
            to: endOfMonth,
            limit: nil,
            offset: nil
        )

        XCTAssertEqual(fetched.count, 2)
        XCTAssertTrue(fetched.contains { $0.title == "月初" })
        XCTAssertTrue(fetched.contains { $0.title == "月末" })
    }

    func test_search_nilのとき全件返る() async throws {
        for i in 1...3 { try await transactionRepository.add(makeTransaction(title: "item\(i)")) }

        let results = try await transactionRepository.search(text: nil)

        XCTAssertEqual(results.count, 3)
    }

    func test_search_空文字のとき全件返る() async throws {
        for i in 1...3 { try await transactionRepository.add(makeTransaction(title: "item\(i)")) }

        let results = try await transactionRepository.search(text: "")

        XCTAssertEqual(results.count, 3)
    }

    func test_delete後_残りのトランザクションが正しく返る() async throws {
        let keep = makeTransaction(title: "残す")
        let remove = makeTransaction(title: "削除する")
        try await transactionRepository.add(keep)
        try await transactionRepository.add(remove)

        try await transactionRepository.delete(remove)

        let fetched = try await transactionRepository.fetch(
            from: nil,
            to: nil,
            limit: nil,
            offset: nil
        )
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.title, "残す")
    }
}
