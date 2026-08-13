//
//  CustomSegmentedControl.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/28
//
//

import SwiftUI

struct CustomSegmentedControl: View {
    @Namespace private var animation
    @Binding var selectedType: TransactionType

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                HStack {
                    Image(systemName: type.imageName)
                    Text(type.rawValue)
                }
                .hSpacing()
                .padding(.vertical, 10)
                .background {
                    if type == selectedType {
                        Capsule()
                            .fill(.background)
                            .matchedGeometryEffect(id: "TYPE", in: animation)
                    }
                }
                .contentShape(.capsule)
                .onTapGesture {
                    withAnimation(.snappy) {
                        if selectedType != type {
                            selectedType = type
                        }
                    }
                }
            }
        }
        .background(AppTheme.segmentBackground, in: .capsule)
        .padding(.top, 5)
    }
}
