//
//  View+Extensions.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/10
//
//

import SwiftUI

extension View {
    @ViewBuilder
    func hSpacing(_ alignment: Alignment = .center) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    @ViewBuilder
    func vSpacing(_ alignment: Alignment = .center) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }

    var safeArea: UIEdgeInsets {
        if let windowScene = (UIApplication.shared.connectedScenes.first as? UIWindowScene) {
            return windowScene.keyWindow?.safeAreaInsets ?? .zero
        }

        return .zero
    }

    func format(date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }

    func currencyString(_ value: Double, allowedDigits: Int = 2) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = allowedDigits

        return formatter.string(from: .init(value: value)) ?? ""
    }

    var currencySymbol: String {
        let locale = Locale.current

        return locale.currencySymbol ?? ""
    }

    nonisolated func total(_ transactions: [TransactionModel], type: TransactionType) -> Double {
        return transactions.filter({ $0.type == type })
            .reduce(Double.zero) { partialResult, transaction in
                return partialResult + transaction.amount
            }
    }
}
