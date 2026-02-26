//
//  NoTransactionView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/26
//
//

import SwiftUI

struct NoTransactionView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 56))
                .foregroundStyle(.tertiary)

            Text("取引がありません")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    NoTransactionView()
}
