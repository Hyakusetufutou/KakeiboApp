//
//  ThemeManager.swift
//  KakeiboApp
//  
//  Created by Hyakusetufutou on 2025/09/07
//  
//

import Foundation

@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme = .light
    
    init() {
        setTheme(.light)
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(themeKey(theme), forKey: "selectedTheme")
    }
    
    private func themeKey(_ theme: AppTheme) -> String {
        switch theme {
        case .light: return "light"
        case .dark: return "dark"
        default: return "light"
        }
    }
}
