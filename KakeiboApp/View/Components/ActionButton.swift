//
//  ActionButton.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/25
//
//

import SwiftUI

struct ActionButton: View {
    let imageName: String
    let onTapped: () -> Void

    var body: some View {
        Button {
            onTapped()
        } label: {
            Image(systemName: imageName)
                .font(.title3)
                .foregroundStyle(.primary)
                .frame(width: 44, height: 44)
                .background {
                    Capsule()
                        .fill(.background)
                        .shadow(color: Color(.label).opacity(0.08), radius: 8, x: 0, y: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ActionButton(imageName: "calendar", onTapped: {})
}
