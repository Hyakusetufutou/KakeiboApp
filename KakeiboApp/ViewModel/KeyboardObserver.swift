//
//  KeyboardObserver.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/01/03
//
//

import Combine
import UIKit

final class KeyboardObserver: ObservableObject {
    @Published var isVisible: Bool = false

    init() {
        let willShow = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillShowNotification)
            .map { _ in true }

        let willHide = NotificationCenter.default
            .publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in false }

        Publishers.Merge(willShow, willHide)
            .receive(on: RunLoop.main)
            .assign(to: &$isVisible)
    }
}
