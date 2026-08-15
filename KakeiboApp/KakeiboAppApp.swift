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
    @StateObject private var appViewModel = ViewModelFactory()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentTabView(factory: appViewModel)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
