//
//  LockView.swift
//  LockSwiftUIView
//
//  Created by Hyakusetufutou on 2025/12/10
//
//

import SwiftUI
import LocalAuthentication

struct LockView: View {
    @Binding var isUnlocked: Bool
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isAuthenticating = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)

                Text("アプリがロックされています")
                    .font(.title2)
                    .foregroundColor(.white)

                Button(action: {
                    if !isAuthenticating {
                        authenticate()
                    }
                }) {
                    HStack {
                        if isAuthenticating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "faceid")
                            Text("ロックを解除")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 180)
                    .background(isAuthenticating ? Color.gray : Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isAuthenticating)

                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            }
        }
        .onAppear {
            Task {
                if !isAuthenticating && !isUnlocked {
                    authenticate()
                }
            }
        }
    }

    private func authenticate() {
        // 既に認証中の場合は処理しない
        guard !isAuthenticating else { return }

        isAuthenticating = true
        showError = false
        errorMessage = ""

        let context = LAContext()
        var error: NSError?

        // 生体認証が利用可能かチェック
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "アプリのロックを解除するために認証が必要です"

            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, authenticationError in
                DispatchQueue.main.async {
                    handleAuthenticationResult(success: success, error: authenticationError)
                }
            }
        } else {
            // 生体認証が利用できない場合はパスコードで認証
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                let reason = "アプリのロックを解除するために認証が必要です"

                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) {
                    success,
                    authenticationError in
                    DispatchQueue.main.async {
                        handleAuthenticationResult(success: success, error: authenticationError)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    isAuthenticating = false
                    showError = true
                    errorMessage = "デバイスで認証が利用できません"
                }
            }
        }
    }

    private func handleAuthenticationResult(success: Bool, error: Error?) {
        isAuthenticating = false

        if success {
            withAnimation {
                isUnlocked = true
            }
        } else {
            if let error = error as? LAError {
                // ユーザーがキャンセルした場合はエラーメッセージを表示しない
                if error.code == .userCancel {
                    showError = false
                    return
                }

                // システムキャンセル（アプリ切り替えなど）の場合も無視
                if error.code == .systemCancel {
                    showError = false
                    return
                }

                showError = true
                errorMessage = getErrorMessage(error)
            } else {
                showError = true
                errorMessage = "認証に失敗しました"
            }
        }
    }

    private func getErrorMessage(_ error: LAError) -> String {
        switch error.code {
        case .authenticationFailed:
            return "認証に失敗しました"
        case .userCancel:
            return "認証がキャンセルされました"
        case .userFallback:
            return "パスコードを使用してください"
        case .biometryNotAvailable:
            return "生体認証が利用できません"
        case .biometryNotEnrolled:
            return "生体認証が設定されていません"
        case .biometryLockout:
            return "試行回数が多すぎます。パスコードで解除してください"
        case .passcodeNotSet:
            return "デバイスにパスコードが設定されていません"
        case .systemCancel:
            return ""  // システムキャンセルは通常表示しない
        default:
            return "認証エラーが発生しました（コード: \(error.code.rawValue)）"
        }
    }
}
