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

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default
    )
    private var items: FetchedResults<Item>

    @State private var activeTab: TabModel = .home
    @State private var isTabBarHidden = false
    @State private var isPresentInputView = false

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

                GraphView()
                    .tag(TabModel.graph)

                Text("SettingView")
                    .tag(TabModel.setting)
            }

            CustomTabBar(activeTab: $activeTab, isPresentInputView: $isPresentInputView)
        }
        .fullScreenCover(isPresented: $isPresentInputView) {
            Text("InputView")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

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
