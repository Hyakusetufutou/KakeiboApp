//
//  UIView+Extensions.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import SwiftUI

extension UIView {
    var tabController: UITabBarController? {
        if let controller = sequence(
            first: self,
            next: {
                $0.next
            }
        )
        .first(where: { $0 is UITabBarController }) as? UITabBarController {
            return controller
        }

        return nil
    }
}
