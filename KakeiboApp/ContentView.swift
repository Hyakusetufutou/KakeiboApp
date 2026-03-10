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
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("isAppLockEnabled") private var isAppLockEnabled = false
    @AppStorage("lockWhenAppGoesBackground") private var lockWhenAppGoesBackground = false

    @State private var selectedTab: TabModel = .home
    @State private var isUnlocked = true

    @StateObject private var homeViewModel: HomeViewModel
    @StateObject private var calendarViewModel: CalendarViewModel
    @StateObject private var graphViewModel: GraphViewModel
    @StateObject private var transactionInputViewModel: TransactionInputViewModel
    @StateObject private var categoryInputViewModel: CategoryInputViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var categoryListViewModel: CategoryListViewModel

    init(factory: ViewModelFactory) {
        _homeViewModel = StateObject(wrappedValue: factory.homeViewModel)
        _calendarViewModel = StateObject(wrappedValue: factory.calendarViewModel)
        _graphViewModel = StateObject(wrappedValue: factory.graphViewModel)
        _transactionInputViewModel = StateObject(wrappedValue: factory.transactionInputViewModel)
        _categoryInputViewModel = StateObject(wrappedValue: factory.categoryInputViewModel)
        _searchViewModel = StateObject(wrappedValue: factory.searchViewModel)
        _categoryListViewModel = StateObject(wrappedValue: factory.categoryListViewModel)
    }

    var body: some View {
        ZStack {
            mainTabView
                .blur(radius: shouldShowLockScreen ? 10 : 0)

            if shouldShowLockScreen {
                LockView(isUnlocked: $isUnlocked)
            }
        }
        .fullScreenCover(
            isPresented: $transactionInputViewModel.isPresentInputView
        ) {
            TransactionInputView(
                transactionInputViewModel: transactionInputViewModel,
                categoryInputViewModel: categoryInputViewModel
            )
        }
        .fullScreenCover(isPresented: $searchViewModel.isPresented) {
            SearchView(
                searchViewModel: searchViewModel,
                transactionInputViewModel: transactionInputViewModel
            )
        }
        .onAppear {
            if isAppLockEnabled {
                isUnlocked = false
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background,
                isAppLockEnabled,
                lockWhenAppGoesBackground
            {
                isUnlocked = false
            } else if phase == .active {
                calendarViewModel.resetDateRangeIfNeeded()
                homeViewModel.resetDateRangeIfNeeded()
            }
        }
    }
}

extension ContentView {
    fileprivate var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                homeViewModel: homeViewModel,
                searchViewModel: searchViewModel,
                transactionInputViewModel: transactionInputViewModel
            )
            .tabItem {
                Label(TabModel.home.title, systemImage: TabModel.home.rawValue)
            }
            .tag(TabModel.home)

            CalendarView(
                calendarViewModel: calendarViewModel,
                transactionInputViewModel: transactionInputViewModel
            )
            .tabItem {
                Label(TabModel.calendar.title, systemImage: TabModel.calendar.rawValue)
            }
            .tag(TabModel.calendar)

            GraphView(
                graphViewModel: graphViewModel,
                transactionInputViewModel: transactionInputViewModel,
                categoryInputViewModel: categoryInputViewModel,
                categoryListViewModel: categoryListViewModel
            )
            .tabItem {
                Label(TabModel.graph.title, systemImage: TabModel.graph.rawValue)
            }
            .tag(TabModel.graph)

            SettingView()
                .tabItem {
                    Label(TabModel.setting.title, systemImage: TabModel.setting.rawValue)
                }
                .tag(TabModel.setting)
        }
    }
}

extension ContentView {
    fileprivate var shouldShowLockScreen: Bool {
        isAppLockEnabled && !isUnlocked
    }

    fileprivate func handleInitialLockState() {
        if isAppLockEnabled {
            isUnlocked = false
        }
    }

    fileprivate func handleScenePhaseChange(_ phase: ScenePhase) {
        guard isAppLockEnabled else { return }

        if phase == .background && lockWhenAppGoesBackground {
            isUnlocked = false
        }
    }
}

#Preview {
    ContentView(factory: ViewModelFactory())
        .environmentObject(ViewModelFactory())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
