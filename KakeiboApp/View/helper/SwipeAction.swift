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
    var cornerRadius: CGFloat = 0
    @ViewBuilder var content: Content
    let onDelete: () -> Void

    private let actionWidth: CGFloat = 60
    private let deleteWidth: CGFloat = 1000
    private let swipeThreshold: CGFloat = 50

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
                .gesture(DragGesture().onChanged(onChanged(value:)).onEnded(onEnd(value:)))
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func onChanged(value: DragGesture.Value) {
        guard abs(value.translation.width) > abs(value.translation.height) else { return }
        if value.translation.width < 0 {
            startSwiping = true
            if isSwiped {
                withAnimation {
                    offset = value.translation.width - actionWidth
                }
            } else {
                withAnimation {
                    offset = value.translation.width
                }
            }
        }
    }

    private func onEnd(value: DragGesture.Value) {
        guard abs(value.translation.width) > abs(value.translation.height) else {
            reset()
            return
        }
        withAnimation(.easeOut) {
            if value.translation.width < 0 {
                if -value.translation.width > UIScreen.main.bounds.width / 2 {
                    delete()
                } else if -offset > swipeThreshold {
                    open()
                } else {
                    close()
                }
            } else {
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
        isSwiped ? open() : close()
    }
}
