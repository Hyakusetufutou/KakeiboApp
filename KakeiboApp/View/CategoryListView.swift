//
//  CategoryListView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/24
//
//

import SwiftUI

struct CategoryListView: View {
    @ObservedObject var categoryViewModel: CategoryViewModel

    init(categoryViewModel: CategoryViewModel) {
        self.categoryViewModel = categoryViewModel
    }

    var body: some View {
        VStack {
            List {
                ForEach(categoryViewModel.categories) { category in
                    Text(category.name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                categoryViewModel.delete(category)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .tint(.red)
                        }
                }
            }
        }
    }
}

#Preview {
    CategoryListView(
        categoryViewModel: CategoryViewModel(repository: CategoryRepository())
    )
}
