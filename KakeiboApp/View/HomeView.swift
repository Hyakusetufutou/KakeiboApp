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
                LazyVStack(spacing: 10, pinnedViews: [.sectionHeaders]) {
                    VStack {
                        headerView()
                        sectionView()
                            .padding(.horizontal, 9)
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
    }

    @ViewBuilder
    func sectionView() -> some View {
        Text(
            "\(format(date: homeViewModel.startDate, format: "yyyy年MM月dd日")) ~ \(format(date: homeViewModel.endDate, format: "yyyy年MM月dd日"))"
        )
        .font(.caption2)
        .foregroundStyle(.gray)
        .hSpacing(.leading)

        VStack {
            CardView(
                income: total(homeViewModel.filterdTransactions, type: .income),
                expense: total(homeViewModel.filterdTransactions, type: .expense)
            )
            .padding(.bottom, 8)

            /// Custom Segmented Control
            CustomSegmentedControl(selectedType: $homeViewModel.selectedType)
                .padding(.bottom, 10)

            if homeViewModel.filterdTransactions.isEmpty {
                VStack {
                    Text("取引なし")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                    Image(systemName: "xmark.seal.fill")
                        .font(.custom("", size: 100))
                }
                .padding(.top, 20)

            } else {
                ForEach(
                    homeViewModel.filterdTransactions
                ) {
                    transaction in
                    NavigationLink(value: transaction) {
                        TransactionCardView(
                            transaction: transaction,
                            category: homeViewModel.categoryFind(id: transaction.categoryId),
                            onDelete: { transaction in
                                homeViewModel.deleteTransaction(transaction)
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

            Button {
                homeViewModel.showFilterView = true
            } label: {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background {
                        Capsule()
                            .fill(.white)
                            .shadow(color: .gray.opacity(0.3), radius: 8, y: 1)
                    }
            }
            .buttonStyle(.plain)

            Button {
                transactionInputViewModel.presentInputView()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background {
                        Capsule()
                            .fill(.white)
                            .shadow(color: .gray.opacity(0.3), radius: 8, y: 1)
                    }
            }
            .buttonStyle(.plain)
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
