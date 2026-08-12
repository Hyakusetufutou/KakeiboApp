//
//  SearchView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/11/16
//
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                contentView
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton
                }
            }
            .navigationTitle("検索")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $searchViewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "取引を検索"
            )
            .alert("エラー", isPresented: errorAlertBinding) {
                Button("OK") { searchViewModel.clearError() }
            } message: {
                if let errorMessage = searchViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if searchViewModel.searchText.isEmpty {
            EmptyStateView(icon: "magnifyingglass", message: "キーワードを入力してください")
        } else if searchViewModel.isLoading {
            loadingView
        } else if searchViewModel.resultTransactions.isEmpty {
            EmptyStateView(icon: "doc.text.magnifyingglass", message: "該当する取引がありません")
        } else {
            searchResults
                .padding()
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        List {
            ForEach(searchViewModel.resultTransactions) { transaction in
                TransactionCardView(
                    transaction: transaction,
                    category: searchViewModel.findCategory(id: transaction.categoryId),
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                .contentShape(Rectangle())
                .onTapGesture {
                    transactionInputViewModel.presentInputView(for: transaction)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        searchViewModel.deleteTransaction(transaction)
                    } label: {
                        Label("", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("検索中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        Button {
            searchViewModel.isPresented = false
        } label: {
            Image(systemName: "xmark")
                .font(.title3)
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Helper

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { searchViewModel.errorMessage != nil },
            set: { if !$0 { searchViewModel.clearError() } }
        )
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()
    SearchView(
        searchViewModel: viewModelFactory.searchViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel
    )
}
