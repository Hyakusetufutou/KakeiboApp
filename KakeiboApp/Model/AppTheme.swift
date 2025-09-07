//
//  AppTheme.swift
//  KakeiboApp
//  
//  Created by Hyakusetufutou on 2025/09/07
//  
//

import SwiftUI

struct AppTheme: Equatable {
    let primary: Color
    let background: Color
    
    static let light = AppTheme(
        primary: Color("PrimaryLight"),
        background: Color("BackgroundLight")
    )
    
    static let dark = AppTheme(
        primary: Color("PrimaryDark"),
        background: Color("BackgroundDark")
    )
}
