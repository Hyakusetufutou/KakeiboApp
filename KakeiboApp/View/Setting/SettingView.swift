//
//  SettingView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/22
//
//

import SwiftUI

struct SettingView: View {
    /// User Properties
    @AppStorage("userName") private var userName: String = ""
    /// App Lock Properties
    @AppStorage("isAppLockEnabled") private var isAppLockEnabled: Bool = false
    @AppStorage("lockWhenAppGoesBackground") private var lockWhenAppGoesBackground: Bool = false
    /// ColorScheme
    @AppStorage("appearance") private var appearanceRawValue = AppAppearance.system.rawValue

    private var appearance: AppAppearance {
        AppAppearance(rawValue: appearanceRawValue) ?? .system
    }

    var body: some View {
        NavigationStack {
            List {
                Section("ユーザー名") {
                    TextField("山田太郎", text: $userName)
                        .submitLabel(.done)
                        .autocorrectionDisabled(true)
                        .textInputAutocapitalization(.never)
                }

                Section("ロック") {
                    Toggle("アプリのロックを許可", isOn: $isAppLockEnabled)
                        .animation(.snappy, value: isAppLockEnabled)

                    if isAppLockEnabled {
                        Toggle("バックグラウンド時のロックを許可", isOn: $lockWhenAppGoesBackground)
                    }
                }

                Section("外観") {
                    Picker("カラーモード", selection: $appearanceRawValue) {
                        ForEach(AppAppearance.allCases) { appearance in
                            Text(appearance.title)
                                .tag(appearance.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("設定")
        }
    }
}

#Preview {
    SettingView()
}
