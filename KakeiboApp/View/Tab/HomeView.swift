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
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    init(homeViewModel: HomeViewModel, transactionInputViewModel: TransactionInputViewModel) {
        self.homeViewModel = homeViewModel
        self.transactionInputViewModel = transactionInputViewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        sectionView()
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 16)
                    } header: {
                        headerView()
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .blur(radius: homeViewModel.showFilterView ? 8 : 0)
            .disabled(homeViewModel.showFilterView)
        }
        .overlay {
            if homeViewModel.showFilterView {
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
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(
            .spring(response: 0.3, dampingFraction: 0.8),
            value: homeViewModel.showFilterView
        )
        .alert("エラー", isPresented: .constant(homeViewModel.errorMessage != nil)) {
            Button("OK") {
                homeViewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = homeViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    func sectionView() -> some View {
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

            CustomSegmentedControl(selectedType: $homeViewModel.selectedType)

            if homeViewModel.filteredTransactions.isEmpty {
                NoTransactionView()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(homeViewModel.filteredTransactions) { transaction in
                        NavigationLink(value: transaction) {
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
                                transactionInputViewModel.presentInputView(transaction)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func headerView() -> some View {
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

                Spacer(minLength: 0)

                ActionButton(imageName: "calendar") {
                    homeViewModel.showFilterView = true
                }

                ActionButton(imageName: "plus") {
                    transactionInputViewModel.presentInputView()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                Color(.systemGroupedBackground)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
            }
        }
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()
    HomeView(
        homeViewModel: viewModelFactory.homeViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel
    )
}
