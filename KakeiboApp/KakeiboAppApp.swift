//
//  KakeiboAppApp.swift
//  KakeiboApp
//  
//  Created by Hyakusetufutou on 2025/09/07
//  
//

import SwiftUI

@main
struct KakeiboAppApp: App {
    @StateObject private var themeManager = ThemeManager()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(themeManager)
        }
    }
}
