//
//  CategoryInputView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/24
//
//

import SwiftUI

struct CategoryInputView: View {
    private var categories: [CategoryModel] = [.mock1, .mock2, .mock3]
    var body: some View {
        VStack {
            List {
                ForEach(categories) { category in
                    Text(category.name)
                }
                .onDelete { indexSet in
                    //                    categories.remove(atOffsets: indexSet)
                }
            }
        }
    }
}

#Preview {
    CategoryInputView()
}
