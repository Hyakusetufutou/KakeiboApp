//
//  SwipeAction.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/09
//
//

import SwiftUI

struct SwipeAction<Content: View>: View {
    @State private var offset: CGFloat = 0
    @State private var isSwiped = false
    @State private var startSwiping = false
    @State private var dragDirection: DragDirection = .none

    var cornerRadius: CGFloat = 0
    @ViewBuilder var content: Content
    let onDelete: () -> Void

    private let actionWidth: CGFloat = 60
    private let deleteWidth: CGFloat = 1000
    private let swipeThreshold: CGFloat = 50
    private let directionThreshold: CGFloat = 10

    var body: some View {
        ZStack {
            if startSwiping {
                Color.red
            }

            HStack {
                Spacer()

                Button {
                    withAnimation(.easeIn) {
                        onDelete()
                    }
                } label: {
                    Image(systemName: "trash")
                        .frame(width: actionWidth)
                        .foregroundStyle(.white)
                }
            }

            content
                .contentShape(Rectangle())
                .offset(x: offset)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged(onChanged(value:))
                        .onEnded(onEnd(value:))
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func onChanged(value: DragGesture.Value) {
        // ドラッグ方向を最初に判定
        if dragDirection == .none {
            let horizontalAmount = abs(value.translation.width)
            let verticalAmount = abs(value.translation.height)

            if horizontalAmount > directionThreshold || verticalAmount > directionThreshold {
                dragDirection = horizontalAmount > verticalAmount ? .horizontal : .vertical
            }
        }

        // 水平方向のドラッグのみ処理
        guard dragDirection == .horizontal else { return }

        if value.translation.width < 0 {
            startSwiping = true
            if isSwiped {
                offset = value.translation.width - actionWidth
            } else {
                offset = value.translation.width
            }
        } else if isSwiped {
            // スワイプされている状態で右にドラッグした場合
            offset = value.translation.width - actionWidth
        }
    }

    private func onEnd(value: DragGesture.Value) {
        defer {
            dragDirection = .none
        }

        // 垂直方向のドラッグの場合は何もしない
        guard dragDirection == .horizontal else {
            reset()
            return
        }

        withAnimation(.easeOut(duration: 0.25)) {
            if value.translation.width < 0 {
                // 左スワイプ
                if -value.translation.width > UIScreen.main.bounds.width / 2 {
                    delete()
                } else if -offset > swipeThreshold {
                    open()
                } else {
                    close()
                }
            } else {
                // 右スワイプ（閉じる）
                close()
            }
        }
    }

    private func open() {
        isSwiped = true
        offset = -actionWidth
    }

    private func close() {
        startSwiping = false
        isSwiped = false
        offset = 0
    }

    private func delete() {
        offset = -deleteWidth
        onDelete()
    }

    private func reset() {
        if isSwiped {
            withAnimation(.easeOut(duration: 0.25)) {
                open()
            }
        } else {
            close()
        }
    }
}

// MARK: - Helper Enum
private enum DragDirection {
    case none
    case horizontal
    case vertical
}
