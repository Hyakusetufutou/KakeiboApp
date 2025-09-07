//
//  CustomTabBar.swift
//  KakeiboApp
//  
//  Created by Hyakusetufutou on 2025/09/07
//  
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var activeTab: TabModel
    @Binding var isPresentInputView: Bool
    @Namespace private var animation
    var body: some View {
        HStack {
            HStack(spacing: 0) {
                ForEach(TabModel.allCases, id: \.rawValue) { tab in
                    Button {
                        activeTab = tab
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: tab.rawValue)
                                .font(.title3.bold())
                                .frame(width: 30, height: 30)
                            
                            if activeTab == tab {
                                Text(tab.title)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                            }
                        }
                        .foregroundStyle(
                            activeTab == tab ?
                                .white : .gray
                        )
                        .padding(.vertical, 2)
                        .padding(.leading, 10)
                        .padding(.trailing, 15)
                        .contentShape(.rect)
                        .background {
                            if activeTab == tab {
                                Capsule()
                                    .fill(.blue)
                                    .matchedGeometryEffect(
                                        id: "ACTIVETAB",
                                        in: animation
                                    )
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 5)
            .frame(height: 45)
            .background(
                .background
                    .shadow(.drop(color: .black.opacity(0.08), radius: 5, x: 5, y: 5))
                    .shadow(.drop(color: .black.opacity(0.06), radius: 5, x: -5, y: -5)),
                in: .capsule
            )
            .zIndex(10)
            
            Button {
                if activeTab != .graph {
                    isPresentInputView = true
                }
            } label: {
                Image(
                    systemName: activeTab == .graph
                    ? "folder.fill.badge.plus" : "plus"
                )
                .font(.title3)
                .frame(width: 42, height: 42)
                .foregroundStyle(.white)
                .background(.blue.gradient)
                .clipShape(.circle)
            }
        }
        .padding(.bottom, 5)
        .animation(.smooth(duration: 0.3, extraBounce: 0), value: activeTab)
    }
}

#Preview {
    ContentView()
}
