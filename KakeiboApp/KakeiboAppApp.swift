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
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
