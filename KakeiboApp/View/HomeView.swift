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
    @Namespace private var animation

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
            .background(.gray.opacity(0.15))
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
        Button {
            homeViewModel.showFilterView = true
        } label: {
            Text(
                "\(format(date: homeViewModel.startDate, format: "yyyy/MM/dd")) ~ \(format(date: homeViewModel.endDate, format: "yyyy/MM/dd"))"
            )
            .font(.caption2)
            .foregroundStyle(.gray)
        }
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
                        category: homeViewModel.categoryViewModel.find(id: transaction.categoryId),
                        onDelete: { transaction in
                            homeViewModel.transactionViewModel.delete(transaction)
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
                    .foregroundStyle(.gray)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: 50, height: 42)
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                            .blur(radius: 2)
                    }
            }

            Button {
                transactionInputViewModel.isPresentInputView = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundStyle(.gray)
                    .padding(8)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .frame(width: 50, height: 42)
                            .foregroundStyle(.white)
                            .shadow(radius: 1)
                            .blur(radius: 2)
                    }
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
    let categoryRepository = CategoryRepository()
    let transactionViewModel = TransactionViewModel(
        transactionRepostory: TransactionRepository(categoryRepository: categoryRepository),
        categoryRepository: categoryRepository
    )
    HomeView(
        homeViewModel: HomeViewModel(
            transactionViewModel: transactionViewModel,
            categoryViewModel: CategoryViewModel(repository: categoryRepository)
        ),
        transactionInputViewModel: TransactionInputViewModel(
            transactionViewModel: transactionViewModel,
            categoryViewModel: CategoryViewModel(repository: categoryRepository)
        )
    )
}
