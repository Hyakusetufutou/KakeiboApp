//
//  PieChartView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/18
//
//

import SwiftUI

struct PieChartView: View {
    let data: [CategorySummary]

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let angles = makeAngles()

            ZStack {
                ForEach(Array(data.enumerated()), id: \.element.id) { index, item in
                    let startAngle = angles[index]
                    let endAngle = index < data.count - 1 ? angles[index + 1] : .degrees(360)
                    let midAngle = Angle(degrees: (startAngle.degrees + endAngle.degrees) / 2)
                    let adjustedAngle = midAngle - .degrees(90)
                    let labelRadius = radius * 0.68

                    PieSlice(startAngle: startAngle, endAngle: endAngle)
                        .fill(item.color)
                        .overlay(
                            PieSlice(startAngle: startAngle, endAngle: endAngle)
                                .stroke(AppTheme.background, lineWidth: 2)
                        )

                    if endAngle - startAngle > .degrees(18) {
                        Text(item.categoryName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(.black.opacity(0.25), in: Capsule())
                            .position(
                                x: center.x + CGFloat(cos(adjustedAngle.radians)) * labelRadius,
                                y: center.y + CGFloat(sin(adjustedAngle.radians)) * labelRadius
                            )
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
    }

    private var accessibilitySummary: String {
        data.map { "\($0.categoryName) \(currencyString($0.totalAmount, allowedDigits: 0))" }
            .joined(separator: "、")
    }

    private func makeAngles() -> [Angle] {
        let amounts = data.map { NSDecimalNumber(decimal: $0.totalAmount).doubleValue }
        let total = amounts.reduce(0, +)

        guard total > 0 else { return Array(repeating: .zero, count: data.count) }

        var angles: [Angle] = []
        var current: Double = 0

        for amount in amounts {
            angles.append(.degrees(current))
            current += (amount / total) * 360
        }

        return angles
    }
}

// MARK: - PieSlice

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.35
        let start = startAngle - .degrees(90)
        let end = endAngle - .degrees(90)

        path.move(to: center)
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: start,
            endAngle: end,
            clockwise: false
        )
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: end,
            endAngle: start,
            clockwise: true
        )
        path.closeSubpath()

        return path
    }
}

#Preview {
    PieChartView(data: [.mock1, .mock2, .mock3])
}
