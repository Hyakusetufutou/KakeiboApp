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
                transactionSection
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
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
                DateFilterView(
                    start: homeViewModel.startDate,
                    end: homeViewModel.endDate,
                    onSubmit: { start, end in
                        homeViewModel.dateRange = DateRange(start: start, end: end)
                        homeViewModel.showFilterView = false
                    },
                    onClose: {
                        homeViewModel.showFilterView = false
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
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

    // MARK: - Sections

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
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 0, trailing: 16))
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
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private var controlSection: some View {
        Section {
            HStack(spacing: 16) {
                CustomSegmentedControl(selectedType: $homeViewModel.selectedType)

                ActionButton(imageName: "calendar", accessibilityLabel: "期間を絞り込む") {
                    homeViewModel.showFilterView = true
                }
            }
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
        .padding(.vertical, 8)
    }

    private var transactionSection: some View {
        Section {
            if homeViewModel.filteredTransactions.isEmpty {
                NoTransactionView()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(homeViewModel.filteredTransactions) { transaction in
                    TransactionCardView(
                        transaction: transaction,
                        category: homeViewModel.categoryFind(id: transaction.categoryId)
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        transactionInputViewModel.presentInputView(for: transaction)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await homeViewModel.deleteTransaction(transaction)
                            }
                        } label: {
                            Label("", systemImage: "trash")
                        }
                    }
                    .onAppear {
                        if transaction.id == homeViewModel.filteredTransactions.last?.id,
                            homeViewModel.hasMoreData
                        {
                            Task {
                                await homeViewModel.loadMore()
                            }
                        }
                    }
                }

                if homeViewModel.isLoading && !homeViewModel.filteredTransactions.isEmpty {
                    loadingIndicator
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
    }

    private var loadingIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .padding()
            Spacer()
        }
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
