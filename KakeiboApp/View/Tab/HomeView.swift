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
            ScrollView(.vertical) {
                LazyVStack(spacing: 8, pinnedViews: [.sectionHeaders]) {
                    VStack {
                        headerView()
                        sectionView()
                            .padding(.horizontal, 8)
                    }
                }
                .padding(15)
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
                        homeViewModel.startDate = start
                        homeViewModel.endDate = end
                        homeViewModel.showFilterView = false
                    },
                    onClose: {
                        homeViewModel.showFilterView = false
                    }
                )
                .transition(.move(edge: .leading))
            }
        }
        .animation(.snappy, value: homeViewModel.showFilterView)
        .alert("エラー", isPresented: .constant(homeViewModel.errorMessage != nil)) {
            Button("OK") {}
        } message: {
            if let errorMessage = homeViewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    @ViewBuilder
    func sectionView() -> some View {
        VStack {
            Text(
                "\(format(date: homeViewModel.startDate, format: "yyyy年MM月dd日")) ~ \(format(date: homeViewModel.endDate, format: "yyyy年MM月dd日"))"
            )
            .font(.caption2)
            .foregroundStyle(.gray)
            .hSpacing(.leading)

            CardView(
                income: total(homeViewModel.filteredTransactions, type: .income),
                expense: total(homeViewModel.filteredTransactions, type: .expense)
            )
            .padding(.bottom, 8)

            /// Custom Segmented Control
            CustomSegmentedControl(selectedType: $homeViewModel.selectedType)
                .padding(.bottom, 10)

            if homeViewModel.filteredTransactions.isEmpty {
                NoTransactionView()

            } else {
                ForEach(
                    homeViewModel.filteredTransactions
                ) {
                    transaction in
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

    @ViewBuilder
    func headerView() -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("おかえりなさい！")
                    .font(.subheadline)
                    .foregroundStyle(.black.opacity(0.6))

                if !userName.isEmpty {
                    Text(userName)
                        .font(.callout.bold())
                }
            }
            .hSpacing(.leading)

            Spacer(minLength: 0)

            ActionButton(imageName: "calendar") {
                homeViewModel.showFilterView = true
            }

            ActionButton(imageName: "plus") {
                transactionInputViewModel.presentInputView()
            }
        }
        .padding(.bottom, userName.isEmpty ? 10 : 5)
        .background(Color(.systemGroupedBackground))
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()
    HomeView(
        homeViewModel: viewModelFactory.homeViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel
    )
}
