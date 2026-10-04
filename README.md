# かけログ

iOS向けのシンプルな家計簿アプリです。

日々の収入・支出を記録し、カレンダーやグラフからお金の流れを確認できます。

個人開発を通して、SwiftUIを中心としたiOSアプリ開発の設計・実装・テスト・CI・App Store公開までを経験することを目的として開発しました。

## スクリーンショット

<img width="428" height="926" alt="Image" src="https://github.com/user-attachments/assets/088650c4-c3f2-4440-bd14-b7b2f5d486af" />
<img width="428" height="926" alt="Image" src="https://github.com/user-attachments/assets/d1d85f9f-d93e-4220-a0b2-7c58f2a9cacc" />
<img width="428" height="926" alt="Image" src="https://github.com/user-attachments/assets/3fc7c9c4-2ede-40f1-ad35-7adb82fe0bc4" />
<img width="428" height="926" alt="Image" src="https://github.com/user-attachments/assets/d7966158-c8db-4cb3-aa53-3a62b40aa485" />

## 機能

- 収入・支出の登録
- カテゴリ管理
- カレンダーによる収支確認
- 収支グラフ
- 取引履歴検索
- データのバックアップ・復元
- アプリロック
- ダークモード対応

### データ管理

- Core Dataによるローカルデータ管理
- バックアップ・復元機能

## 技術スタック

| 項目 | 技術 |
|---|---|
| 言語 | Swift |
| UI | SwiftUI |
| アーキテクチャ | MVVM + Repository + Store + UseCase |
| データベース | Core Data |
| リアクティブプログラミング | Combine |
| 並行処理 | async/await, Actor |
| テスト | Swift Testing |
| CI | GitHub Actions |
| 最小OSバージョン | iOS 16.0 |
| フォーマット | swift-format |

## アーキテクチャ

MVVMをベースに、ViewModelからStoreを介してRepositoryへアクセスし、データアクセスを行う構成としています。

基本的なデータ操作は以下の構成です。

```text
View
 ↓
ViewModel
 ↓
Store
 ↓
Repository
 ↓
Core Data
```

バックアップ・復元など、複数の処理を組み合わせるアプリケーション固有の処理についてはUseCaseを設けています。

```text
View
 ↓
ViewModel
 ↓
UseCase
 ↓
Store
 ↓
Repository
 ↓
Core Data
```

すべての処理を一律にUseCaseへ分離するのではなく、処理の責務や複雑度に応じてUseCaseの導入範囲を判断しています。

### ポリシー

- Viewとデータアクセス処理を分離
- ViewModelは画面状態とユーザー操作を担当
- Repositoryでデータアクセスを抽象化
- StoreでCore Dataへのアクセスを管理
- 複数の処理を組み合わせる処理にはUseCaseを使用
- 非同期処理にはasync/awaitを使用し、RepositoryをActorとして実装

## テスト

Swift Testingを使用したUnit Testを実装しています。

### Unit Test

- 収支計算
- カテゴリ処理
- 取引登録
- データ変換
- ViewModelの状態変更

## CI

GitHub Actionsを使用してCIを構築しています。

以下の処理を自動化しています。

- swift-formatによるコードフォーマットチェック
- Xcodeプロジェクトのビルド
- Unit Test

`main` / `develop`へのPushおよびPull Requestを契機として、自動的にコードのフォーマットチェック、ビルド、テストを実行しています。

## リリース

### v1.0.0

- 初回リリース
- App Store公開
- iOS 16以降対応

## 今後の改善

今後の追加候補:

- CSVエクスポート
- 家計分析機能
- ウィジェット対応
- iCloud連携の拡張

## Requirements

- iOS 16.0+
- Xcode 16+
- Swift 6
