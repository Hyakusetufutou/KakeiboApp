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

    var total: Double {
        data.reduce(0) { $0 + $1.totalAmount }
    }

    var angles: [Angle] {
        var angles: [Angle] = []
        var currentAngle: Double = 0
        for item in data {
            let ratio = item.totalAmount / total
            let angle = ratio * 360
            angles.append(.degrees(currentAngle))
            currentAngle += angle
        }
        return angles
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            ZStack {
                ForEach(Array(zip(data.indices, data)), id: \.1.id) { (index, item) in
                    let startAngle = angles[index]
                    let endAngle = index < data.count - 1 ? angles[index + 1] : .degrees(360)
                    let midAngle = (startAngle + endAngle) / 2
                    let adjustedAngle = midAngle - .degrees(90)
                    let labelRadius = radius * 0.6

                    PieSlice(startAngle: startAngle, endAngle: endAngle)
                        .fill(item.color)

                    if endAngle - startAngle > .degrees(18) {
                        Text(item.categoryName)
                            .font(.callout)
                            .position(
                                x: center.x + CGFloat(cos(adjustedAngle.radians)) * labelRadius,
                                y: center.y + CGFloat(sin(adjustedAngle.radians)) * labelRadius
                            )
                    }
                }
            }
        }
    }
}

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
