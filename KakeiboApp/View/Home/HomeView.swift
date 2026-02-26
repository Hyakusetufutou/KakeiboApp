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
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        Section {
                            contentSection
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                                .padding(.bottom, 16)
                        } header: {
                            headerView
                        }
                    }
                }
                .refreshable {
                    await homeViewModel.reload()
                }

                if homeViewModel.isLoading && homeViewModel.filteredTransactions.isEmpty {
                    ProgressView("読み込み中...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .blur(radius: homeViewModel.showFilterView ? 8 : 0)
            .disabled(homeViewModel.showFilterView)
        }
        .overlay {
            if homeViewModel.showFilterView {
                Color(.label)
                    .opacity(0.15)
                    .ignoresSafeArea()
                    .transition(.opacity)

                dateFilterOverlay
            }
        }
        .animation(
            .spring(response: 0.3, dampingFraction: 0.8),
            value: homeViewModel.showFilterView
        )
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

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                if !userName.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("おかえりなさい!")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(userName)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .hSpacing(.leading)
                } else {
                    Text("ホーム")
                        .font(.headline)
                        .hSpacing(.leading)
                }

                HStack(spacing: 12) {
                    ActionButton(imageName: "magnifyingglass") {
                        searchViewModel.isPresented = true
                    }

                    ActionButton(imageName: "plus") {
                        transactionInputViewModel.presentInputView()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                Color(.systemGroupedBackground)
                    .shadow(color: Color(.label).opacity(0.08), radius: 2, y: 1)
            }
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(spacing: 12) {
            Text(
                "\(format(date: homeViewModel.dateRange.start, format: "yyyy年MM月dd日")) 〜 \(format(date: homeViewModel.dateRange.end, format: "yyyy年MM月dd日"))"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .hSpacing(.leading)

            CardView(
                income: total(homeViewModel.filteredTransactions, type: .income),
                expense: total(homeViewModel.filteredTransactions, type: .expense)
            )

            HStack(spacing: 16) {
                CustomSegmentedControl(selectedType: $homeViewModel.selectedType)

                ActionButton(imageName: "calendar") {
                    homeViewModel.showFilterView = true
                }
            }

            if homeViewModel.filteredTransactions.isEmpty {
                NoTransactionView()
            } else {
                transactionList
            }
        }
    }

    // MARK: - Transaction List with Pagination

    private var transactionList: some View {
        LazyVStack(spacing: 8) {
            ForEach(homeViewModel.filteredTransactions) { transaction in
                TransactionCardView(
                    transaction: transaction,
                    category: homeViewModel.categoryFind(id: transaction.categoryId),
                    onDelete: { transaction in
                        Task {
                            await homeViewModel.deleteTransaction(transaction)
                        }
                    }
                )
                .onTapGesture {
                    transactionInputViewModel.presentInputView(for: transaction)
                }
                .onAppear {
                    if isLastTransaction(transaction) {
                        Task {
                            await homeViewModel.loadMore()
                        }
                    }
                }
            }

            if homeViewModel.isLoading && !homeViewModel.filteredTransactions.isEmpty {
                loadingIndicator
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

    // MARK: - Date Filter Overlay

    private var dateFilterOverlay: some View {
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
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
            )
        )
    }

    // MARK: - Helper Methods

    private func isLastTransaction(_ transaction: TransactionModel) -> Bool {
        homeViewModel.filteredTransactions.last?.id == transaction.id
            && homeViewModel.hasMoreData
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { homeViewModel.errorMessage != nil },
            set: { if !$0 { homeViewModel.clearError() } }
        )
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()
    HomeView(
        homeViewModel: viewModelFactory.homeViewModel,
        searchViewModel: viewModelFactory.searchViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel
    )
}
