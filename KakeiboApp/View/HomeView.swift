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
                    Section {
                        VStack {
                            sectionView()
                        }
                    } header: {
                        headerView()
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
            "\(format(date: homeViewModel.startDate, format: "yyyy/MM/dd")) ~ \(format(date: homeViewModel.endDate, format: "yyyy/MM/dd"))"
        )
        .font(.caption2)
        .foregroundStyle(.gray)
        .hSpacing(.leading)

        VStack {
            CardView(
                income: total(homeViewModel.filterdTransactions, type: .income),
                expense: total(homeViewModel.filterdTransactions, type: .expense)
            )

            /// Custom Segmented Control
            CustomSegmentedControl(selectedType: $homeViewModel.selectedType)
                .padding(.bottom, 10)

            ForEach(
                homeViewModel.filterdTransactions.filter({
                    $0.type.rawValue == homeViewModel.selectedType.rawValue
                })
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

    @ViewBuilder
    func headerView() -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ホーム")
                    .font(.title.bold())

                if !userName.isEmpty {
                    Text(userName)
                        .font(.callout)
                        .foregroundStyle(.gray)
                }
            }
            .hSpacing(.leading)

            Spacer(minLength: 0)

            Button {
                homeViewModel.showFilterView = true
            } label: {
                Image(systemName: "calendar")
                    .font(.title2)
                    .padding(8)
            }

            Button {
                transactionInputViewModel.presentInputView()
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .padding(8)
            }
        }
        .padding(.bottom, userName.isEmpty ? 10 : 5)
        .background {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(.ultraThinMaterial)
                Divider()
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
