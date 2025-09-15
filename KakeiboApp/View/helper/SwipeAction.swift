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
                        .frame(width: 60)
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
        if value.translation.width < 0 {
            startSwiping = true
            if isSwiped {
                withAnimation {
                    offset = value.translation.width - 60
                }
            } else {
                withAnimation {
                    offset = value.translation.width
                }
            }
        }
    }

    private func onEnd(value: DragGesture.Value) {
        withAnimation(.easeOut) {
            if value.translation.width < 0 {
                if -value.translation.width > UIScreen.main.bounds.width / 2 {
                    offset = -1000
                    onDelete()
                } else if -offset > 50 {
                    isSwiped = true
                    offset = -60
                } else {
                    startSwiping = false
                    isSwiped = false
                    offset = 0
                }
            } else {
                startSwiping = false
                isSwiped = false
                offset = 0
            }
        }
    }
}
