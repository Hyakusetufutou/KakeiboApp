//
//  LockView.swift
//  KakeiboApp
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
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            AppTheme.primaryText.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.cardBackground)

                Text("アプリがロックされています")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.cardBackground)

                unlockButton

                if showError {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            if !isAuthenticating && !isUnlocked {
                authenticate()
            }
        }
    }

    // MARK: - Unlock Button

    private var unlockButton: some View {
        Button {
            if !isAuthenticating { authenticate() }
        } label: {
            HStack(spacing: 8) {
                if isAuthenticating {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(AppTheme.secondaryBackground)
                } else {
                    Image(systemName: "faceid")
                    Text("ロックを解除")
                }
            }
            .font(.headline)
            .foregroundStyle(AppTheme.secondaryBackground)
            .padding()
            .frame(minWidth: 180)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isAuthenticating ? Color(.systemGray) : Color.accentColor)
            )
        }
        .disabled(isAuthenticating)
    }

    // MARK: - Authentication

    private func authenticate() {
        guard !isAuthenticating else { return }

        isAuthenticating = true
        showError = false
        errorMessage = ""

        let context = LAContext()
        var error: NSError?

        let policy: LAPolicy =
            context.canEvaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                error: &error
            ) ? .deviceOwnerAuthenticationWithBiometrics : .deviceOwnerAuthentication

        guard context.canEvaluatePolicy(policy, error: &error) else {
            DispatchQueue.main.async {
                isAuthenticating = false
                showError = true
                errorMessage = "デバイスで認証が利用できません"
            }
            return
        }

        context.evaluatePolicy(
            policy,
            localizedReason: "アプリのロックを解除するために認証が必要です"
        ) { success, authError in
            DispatchQueue.main.async {
                handleAuthenticationResult(success: success, error: authError)
            }
        }
    }

    private func handleAuthenticationResult(success: Bool, error: Error?) {
        isAuthenticating = false

        if success {
            withAnimation { isUnlocked = true }
            return
        }

        guard let laError = error as? LAError else {
            showError = true
            errorMessage = "認証に失敗しました"
            return
        }

        if laError.code == .userCancel || laError.code == .systemCancel {
            showError = false
            return
        }

        showError = true
        errorMessage = errorMessage(for: laError)
    }

    private func errorMessage(for error: LAError) -> String {
        switch error.code {
        case .authenticationFailed: return "認証に失敗しました"
        case .userCancel: return "認証がキャンセルされました"
        case .userFallback: return "パスコードを使用してください"
        case .biometryNotAvailable: return "生体認証が利用できません"
        case .biometryNotEnrolled: return "生体認証が設定されていません"
        case .biometryLockout: return "試行回数が多すぎます。パスコードで解除してください"
        case .passcodeNotSet: return "デバイスにパスコードが設定されていません"
        case .systemCancel: return ""
        default: return "認証エラーが発生しました（コード: \(error.code.rawValue)）"
        }
    }
}
