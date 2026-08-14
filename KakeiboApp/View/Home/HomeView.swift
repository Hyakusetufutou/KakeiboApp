//
//  HomeView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/08
//
//

import SwiftUI

struct HomeView: View {
    @AppStorage("userName") private var userName: String = ""
    @ObservedObject var homeViewModel: HomeViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    init(
        homeViewModel: HomeViewModel,
        searchViewModel: SearchViewModel,
        transactionInputViewModel: TransactionInputViewModel
    ) {
        self.homeViewModel = homeViewModel
        self.searchViewModel = searchViewModel
        self.transactionInputViewModel = transactionInputViewModel
    }

    var body: some View {
        NavigationStack {
            List {
                dateRangeSection
                summarySection
                controlSection

                HomeTransactionSectionView(
                    homeViewModel: homeViewModel,
                    transactionInputViewModel: transactionInputViewModel
                )
            }
            .padding(.horizontal, 16)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .refreshable {
                await homeViewModel.reload()
            }
            .overlay {
                if homeViewModel.isLoading && homeViewModel.filteredTransactions.isEmpty {
                    ProgressView("読み込み中...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle(userName.isEmpty ? "ホーム" : "おかえりなさい、\(userName)さん")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        searchViewModel.isPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel("取引を検索")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        transactionInputViewModel.presentInputView()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("取引を追加")
                }
            }
            .sheet(isPresented: $homeViewModel.showFilterView) {
                HomeDateFilterSheetView(homeViewModel: homeViewModel)
            }
            .alert("エラー", isPresented: errorAlertBinding) {
                Button("OK") {
                    homeViewModel.clearError()
                }
            } message: {
                if let errorMessage = homeViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Subviews (HomeView直下にとどめる軽量な表示)

    private var dateRangeSection: some View {
        Section {
            Text(
                "\(format(date: homeViewModel.dateRange.start, format: "yyyy年MM月dd日")) 〜 \(format(date: homeViewModel.dateRange.end, format: "yyyy年MM月dd日"))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
    }

    private var summarySection: some View {
        Section {
            CardView(
                income: total(homeViewModel.filteredTransactions, type: .income),
                expense: total(homeViewModel.filteredTransactions, type: .expense)
            )
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }

    private var controlSection: some View {
        Section {
            HStack(spacing: 16) {
                GeometryReader {
                    CustomSegmentedControl(
                        selection: $homeViewModel.selectedType,
                        size: $0.size
                    )
                }
                ActionButton(imageName: "calendar", accessibilityLabel: "期間を絞り込む") {
                    homeViewModel.showFilterView = true
                }
            }
            .padding(.top, 4)
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { homeViewModel.errorMessage != nil },
            set: { if !$0 { homeViewModel.clearError() } }
        )
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()

    return HomeView(
        homeViewModel: viewModelFactory.homeViewModel,
        searchViewModel: viewModelFactory.searchViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel
    )
}
