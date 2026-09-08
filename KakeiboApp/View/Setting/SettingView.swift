//
//  SettingView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/22
//
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingView: View {

    // MARK: - User

    @AppStorage("userName")
    private var userName = ""

    // MARK: - App Lock

    @AppStorage("isAppLockEnabled")
    private var isAppLockEnabled = false

    @AppStorage("lockWhenAppGoesBackground")
    private var lockWhenAppGoesBackground = false

    // MARK: - Appearance

    @AppStorage("appearance")
    private var appearanceRawValue = AppAppearance.system.rawValue

    // MARK: - ViewModel

    @ObservedObject
    var settingViewModel: SettingViewModel

    // MARK: - Backup State

    @State private var backupData: Data?
    @State private var selectedBackupData: Data?

    @State private var isShowingExporter = false
    @State private var isShowingImporter = false
    @State private var isShowingRestoreConfirmation = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                Section("ユーザー名") {
                    TextField(
                        "山田太郎",
                        text: $userName
                    )
                    .submitLabel(.done)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                }

                Section("ロック") {
                    Toggle(
                        "アプリのロックを許可",
                        isOn: $isAppLockEnabled
                    )
                    .animation(
                        .snappy,
                        value: isAppLockEnabled
                    )

                    if isAppLockEnabled {
                        Toggle(
                            "バックグラウンド時のロックを許可",
                            isOn: $lockWhenAppGoesBackground
                        )
                    }
                }

                Section("外観") {
                    Picker(
                        "カラーモード",
                        selection: $appearanceRawValue
                    ) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title)
                                .tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("データ") {
                    Button {
                        createBackup()
                    } label: {
                        Label(
                            "バックアップを作成",
                            systemImage: "arrow.down.doc"
                        )
                    }
                    .disabled(settingViewModel.isProcessing)

                    Button {
                        isShowingImporter = true
                    } label: {
                        Label(
                            "バックアップから復元",
                            systemImage: "arrow.up.doc"
                        )
                    }
                    .disabled(settingViewModel.isProcessing)
                }

                Section("サポート") {
                    Link(destination: AppURL.formURL) {
                        Label(
                            "お問い合わせ",
                            systemImage: "envelope"
                        )
                    }

                    Link(destination: AppURL.privacyPolicyURL) {
                        Label("プライバシーポリシー", systemImage: "hand.raised")
                    }
                }
            }
            .navigationTitle("設定")
        }
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleImport(result)
        }
        .fileExporter(
            isPresented: $isShowingExporter,
            document: BackupDocument(
                data: backupData ?? Data()
            ),
            contentType: .json,
            defaultFilename: "kakeibo-backup"
        ) { result in
            handleExport(result)
        }
        .confirmationDialog(
            "バックアップから復元しますか？",
            isPresented: $isShowingRestoreConfirmation
        ) {
            Button("復元", role: .destructive) {
                restoreBackup()
                selectedBackupData = nil
            }

            Button("キャンセル") {
                selectedBackupData = nil
            }
        } message: {
            Text(
                """
                現在の家計簿データは削除され、
                バックアップの内容に置き換えられます。
                """
            )
        }
        .alert(
            "エラー",
            isPresented: Binding(
                get: {
                    settingViewModel.errorMessage != nil
                },
                set: { isPresented in
                    if !isPresented {
                        settingViewModel.errorMessage = nil
                    }
                }
            )
        ) {
            Button("OK") {
                settingViewModel.errorMessage = nil
            }
        } message: {
            Text(settingViewModel.errorMessage ?? "")
        }
    }

    // MARK: - Backup

    private func createBackup() {
        Task {
            let data = await settingViewModel.createBackup()

            guard let data else {
                return
            }

            backupData = data
            isShowingExporter = true
        }
    }

    private func handleImport(
        _ result: Result<URL, Error>
    ) {
        switch result {
        case .success(let url):
            do {
                let data = try Data(contentsOf: url)

                selectedBackupData = data
                isShowingRestoreConfirmation = true
            } catch {
                settingViewModel.errorMessage =
                    ErrorMapper.message(for: error)
            }

        case .failure(let error):
            settingViewModel.errorMessage =
                ErrorMapper.message(for: error)
        }
    }

    private func restoreBackup() {
        guard let data = selectedBackupData else {
            return
        }

        Task {
            await settingViewModel.restoreBackup(
                from: data
            )

            selectedBackupData = nil
        }
    }

    private func handleExport(
        _ result: Result<URL, Error>
    ) {
        switch result {
        case .success:
            break

        case .failure(let error):
            settingViewModel.errorMessage =
                ErrorMapper.message(for: error)
        }
    }

    private func openContactMail() {
        let email = "kakeibo@example.com"
        let subject = "Kakeiboへのお問い合わせ"

        let encodedSubject = subject.addingPercentEncoding(
            withAllowedCharacters: .urlQueryAllowed
        )

        guard
            let url = URL(
                string: "mailto:\(email)?subject=\(encodedSubject ?? "")"
            )
        else {
            return
        }

        UIApplication.shared.open(url)
    }
}

#Preview {
    let factory = ViewModelFactory()
    SettingView(
        settingViewModel: factory.settingViewModel
    )

}
