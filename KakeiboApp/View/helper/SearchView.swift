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
                Button("OK") {
                    searchViewModel.clearError()
                }
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
            emptySearchView
        } else if searchViewModel.isLoading {
            loadingView
        } else if searchViewModel.resultTransactions.isEmpty {
            noResultsView
        } else {
            searchResults
        }
    }

    // MARK: - Search Results

    private var searchResults: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(searchViewModel.resultTransactions) { transaction in
                    TransactionCardView(
                        transaction: transaction,
                        category: searchViewModel.findCategory(id: transaction.categoryId),
                        onDelete: { transaction in
                            Task {
                                await searchViewModel.deleteTransaction(transaction)
                            }
                        }
                    )
                    .onTapGesture {
                        transactionInputViewModel.presentInputView(for: transaction)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Empty States

    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("キーワードを入力してください")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()

            Text("検索中...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("該当する取引がありません")
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
            Image(systemName: "xmark.circle.fill")
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
