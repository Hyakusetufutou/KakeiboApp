//
//  AddCategoryView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/29
//
//

import SwiftUI

struct AddCategoryView: View {
    @State var text = ""
    var onClose: () -> Void
    var onCreate: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("カテゴリ名")
                .font(.caption)

            TextField("食事", text: $text)
                .padding(.horizontal, 10)

                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.1))
                }

            HStack {
                Button {
                    onCreate()
                } label: {
                    Text("作成")
                        .font(.title3)
                        .foregroundStyle(.backgroundLight)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.purple)
                                .opacity(text.isEmpty ? 0.4 : 1)
                        }
                }
                .disabled(text.isEmpty)

                Button {
                    onClose()
                } label: {
                    Text("中止")
                        .font(.title3)
                        .foregroundStyle(.backgroundLight)
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.red)
                        }
                }
            }
        }
        .padding(15)
        .background(.bar, in: .rect(cornerRadius: 10))
        .padding(.horizontal, 30)
    }
}

#Preview {
    AddCategoryView(
        onClose: {},
        onCreate: {}
    )
}
