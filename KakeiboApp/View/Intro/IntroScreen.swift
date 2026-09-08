//
//  IntroScreen.swift
//  Expense Tracker
//
//
//

import SwiftUI

struct IntroScreen: View {

    @AppStorage("isFirstTime")
    private var isFirstTime = true

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // App Icon / Symbol
            Image(systemName: "wallet.pass.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
                .padding(.bottom, 28)

            Text("家計簿へようこそ")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Text("シンプルに、毎日の収支を記録しましょう。")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 10)

            Spacer()
                .frame(height: 55)

            VStack(alignment: .leading, spacing: 28) {

                pointView(
                    symbol: "plus.circle.fill",
                    title: "かんたん収支管理",
                    subTitle: "日々の収入や支出をすばやく記録できます。"
                )

                pointView(
                    symbol: "chart.bar.fill",
                    title: "グラフで見える化",
                    subTitle: "支出の割合や推移をグラフで確認できます。"
                )

                pointView(
                    symbol: "calendar",
                    title: "いつでも振り返り",
                    subTitle: "カレンダーや検索から過去の収支を確認できます。"
                )

                pointView(
                    symbol: "arrow.clockwise.icloud",
                    title: "大切なデータをバックアップ",
                    subTitle: "家計データをバックアップして、いつでも復元できます。"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            Button {
                isFirstTime = false
            } label: {
                Text("はじめる")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        .blue.gradient,
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .accessibilityLabel("Kakeiboをはじめる")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    @ViewBuilder
    private func pointView(
        symbol: String,
        title: String,
        subTitle: String
    ) -> some View {
        HStack(alignment: .top, spacing: 18) {

            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(.blue.gradient)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)

                Text(subTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    IntroScreen()
}
