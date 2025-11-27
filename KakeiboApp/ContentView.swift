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
    @State private var showTabView = true

    @ObservedObject var transactionViewModel: TransactionViewModel
    @ObservedObject var categoryViewModel: CategoryViewModel
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var graphViewModel: GraphViewModel
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel
    @ObservedObject var categoryInputViewModel: CategoryInputViewModel
    @ObservedObject var searchViewModel: SearchViewModel

    init() {
        let viewModelFactory = ViewModelFactory()
        self.transactionViewModel = viewModelFactory.transactionViewModel
        self.categoryViewModel = viewModelFactory.categoryViewModel
        self.homeViewModel = viewModelFactory.homeViewModel
        self.graphViewModel = viewModelFactory.graphViewModel
        self.calendarViewModel = viewModelFactory.calendarViewModel
        self.transactionInputViewModel = viewModelFactory.transactionInputViewModel
        self.categoryInputViewModel = viewModelFactory.categoryInputViewModel
        self.searchViewModel = viewModelFactory.searchViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            if showTabView {
                TabView(selection: $activeTab) {
                    HomeView(
                        homeViewModel: homeViewModel,
                        transactionInputViewModel: transactionInputViewModel
                    )
                    .tag(TabModel.home)
                    .background {
                        if !isTabBarHidden {
                            HideTabBar {
                                isTabBarHidden = true
                            }
                        }
                    }

                    CalendarView(calendarViewModel: calendarViewModel)
                        .tag(TabModel.calendar)

                    GraphView(
                        graphViewModel: graphViewModel,
                        transactionInputViewModel: transactionInputViewModel,
                        categoryInputViewModel: categoryInputViewModel
                    )
                    .tag(TabModel.graph)

                    SettingView()
                        .tag(TabModel.setting)
                }
            } else {
                SearchView(
                    searchViewModel: searchViewModel,
                    categoryViewModel: categoryViewModel,
                    transactionViewModel: transactionViewModel,
                    transactionInputViewModel: transactionInputViewModel
                )
            }

            if !categoryInputViewModel.isPresentInputView {
                CustomTabBar(showSearchBar: true, activeTab: $activeTab) { isExpanded in
                    showTabView = !isExpanded
                } onSearchTextChanged: { searchText in
                    searchViewModel.searchText = searchText
                }

            }
        }
        .fullScreenCover(isPresented: $transactionInputViewModel.isPresentInputView) {
            TransactionInputView(
                viewModel: transactionInputViewModel,
                categoryViewModel: categoryViewModel
            )
        }
        .background {
            Color.gray.opacity(0.15)
                .edgesIgnoringSafeArea(.all)
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
        .environmentObject(ViewModelFactory())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
