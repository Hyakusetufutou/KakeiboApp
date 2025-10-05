//
//  ContentView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @State private var activeTab: TabModel = .home
    @State private var isTabBarHidden = false
    @State private var isPresentInputView = false
    @State private var isPresentCategoryInputView = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $activeTab) {
                HomeView()
                    .tag(TabModel.home)
                    .background {
                        if !isTabBarHidden {
                            HideTabBar {
                                isTabBarHidden = true
                            }
                        }
                    }

                Text("Calendar")
                    .tag(TabModel.calendar)

                GraphView(isPresentCategoryInputView: $isPresentCategoryInputView)
                    .tag(TabModel.graph)

                SettingView()
                    .tag(TabModel.setting)
            }

            if !isPresentCategoryInputView {
                CustomTabBar(
                    activeTab: $activeTab,
                    isPresentInputView: $isPresentInputView,
                    isPresentCategoryInputView: $isPresentCategoryInputView
                )
            }
        }
        .fullScreenCover(isPresented: $isPresentInputView) {
            TransactionInputView(isPresented: $isPresentInputView)
        }
    }
}

struct HideTabBar: UIViewRepresentable {
    var result: () -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear

        DispatchQueue.main.async {
            if let tabController = view.tabController {
                tabController.tabBar.isHidden = true
                result()
            }
        }

        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
