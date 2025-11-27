//
//  CustomTabBar.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/09/07
//
//

import SwiftUI

struct CustomTabBar: View {
    var showSearchBar: Bool = false
    @Binding var activeTab: TabModel
    var onSearchBarExpanded: (Bool) -> Void
    var onSearchTextChanged: (String) -> Void
    /// View Properties
    @GestureState private var isActive: Bool = false
    @State private var isInitialOffsetSet: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var lastDragOffset: CGFloat?
    /// Search Bar Properties
    @State private var isSearchExpanded: Bool = false
    @State private var searchText: String = ""
    @FocusState private var isKeyboardActive: Bool

    var body: some View {
        GeometryReader {
            let size = $0.size
            let tabs = TabModel.allCases.prefix(showSearchBar ? 4 : 5)
            let tabItemWidth = max(
                min(size.width / CGFloat(tabs.count + (showSearchBar ? 1 : 0)), 90),
                60
            )
            let tabItemHeight: CGFloat = 56

            ZStack {
                if isInitialOffsetSet {
                    let mainLayout =
                        isKeyboardActive
                        ? AnyLayout(ZStackLayout(alignment: .leading))
                        : AnyLayout(HStackLayout(spacing: 12))

                    mainLayout {
                        let tabLayout =
                            isSearchExpanded
                            ? AnyLayout(ZStackLayout()) : AnyLayout(HStackLayout(spacing: 0))

                        tabLayout {
                            ForEach(tabs, id: \.rawValue) { tab in
                                tabItemView(
                                    tab,
                                    width: isSearchExpanded ? 45 : tabItemWidth,
                                    height: isSearchExpanded ? 45 : tabItemHeight
                                )
                                .opacity(isSearchExpanded ? (activeTab == tab ? 1 : 0) : 1)
                            }
                        }
                        /// Draggable Active Tab
                        .background(alignment: .leading) {
                            ZStack {
                                Capsule(style: .continuous)
                                    .stroke(.gray.opacity(0.25), lineWidth: 3)
                                    .opacity(isActive ? 1 : 0)

                                Capsule(style: .continuous)
                                    .fill(.background)
                            }
                            .compositingGroup()
                            .frame(width: tabItemWidth, height: tabItemHeight)
                            /// Scaling when drag gesture becomes active
                            .scaleEffect(isActive ? 1.3 : 1)
                            .offset(x: dragOffset)
                            .opacity(isSearchExpanded ? 0 : 1)
                        }
                        .padding(3)
                        .background {
                            tabBarBackground()
                        }
                        .overlay {
                            if isSearchExpanded {
                                Capsule()
                                    .foregroundStyle(.clear)
                                    .contentShape(.capsule)
                                    .onTapGesture {
                                        withAnimation(.bouncy) {
                                            isSearchExpanded = false
                                        }
                                    }
                            }
                        }
                        /// Hiding when keyboard is active
                        .opacity(isKeyboardActive ? 0 : 1)

                        if showSearchBar {
                            expandableSearchBar(height: isSearchExpanded ? 45 : tabItemHeight)
                        }
                    }
                    .optionalGeometryGroup()
                }
            }
            /// Centering Tab Bar
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .onAppear {
                guard !isInitialOffsetSet else { return }
                dragOffset = CGFloat(activeTab.index) * tabItemWidth
                isInitialOffsetSet = true
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 25)
        /// Animations (Customize it as per your needs!)
        .animation(.bouncy, value: dragOffset)
        .animation(.bouncy, value: isActive)
        .animation(.smooth, value: activeTab)
        .animation(.easeInOut(duration: 0.25), value: isKeyboardActive)
        .customOnChange(value: isKeyboardActive) {
            onSearchBarExpanded($0)
        }
        .customOnChange(value: searchText) {
            onSearchTextChanged($0)
        }
    }

    /// Tab Item View
    @ViewBuilder
    private func tabItemView(_ tab: TabModel, width: CGFloat, height: CGFloat) -> some View {
        let tabs = TabModel.allCases.prefix(showSearchBar ? 4 : 5)
        let tabCount = tabs.count - 1
        VStack(spacing: 6) {
            Image(systemName: tab.rawValue)
                .font(.title2)
                .symbolVariant(.fill)

            if !isSearchExpanded {
                Text(tab.title)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .foregroundStyle(activeTab == tab ? accentColor : Color.primary)
        .frame(width: width, height: height)
        .contentShape(.capsule)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating(
                    $isActive,
                    body: { _, out, _ in
                        out = true
                    }
                )
                .onChanged({ value in
                    let xOffset = value.translation.width
                    if let lastDragOffset {
                        let newDragOffset = xOffset + lastDragOffset
                        dragOffset = max(min(newDragOffset, CGFloat(tabCount) * width), 0)
                    } else {
                        lastDragOffset = dragOffset
                    }
                })
                .onEnded({ value in
                    lastDragOffset = nil
                    let landingIndex = Int((dragOffset / width).rounded())
                    /// Safe Check
                    if tabs.indices.contains(landingIndex) {
                        dragOffset = CGFloat(landingIndex) * width
                        activeTab = tabs[landingIndex]
                    }
                })
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded({ _ in
                    activeTab = tab
                    dragOffset = CGFloat(tab.index) * width
                })
        )
        .optionalGeometryGroup()
    }

    /// Tab Bar Background View
    @ViewBuilder
    private func tabBarBackground() -> some View {
        ZStack {
            Capsule(style: .continuous)
                .stroke(.gray.opacity(0.25), lineWidth: 1.5)

            Capsule(style: .continuous)
                .fill(.background.opacity(0.8))

            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        }
    }

    /// Expandable Search Bar
    @ViewBuilder
    private func expandableSearchBar(height: CGFloat) -> some View {
        let searchLayout =
            isKeyboardActive
            ? AnyLayout(HStackLayout(spacing: 12)) : AnyLayout(ZStackLayout(alignment: .trailing))

        searchLayout {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(isSearchExpanded ? .body : .title2)
                    .foregroundStyle(isSearchExpanded ? .gray : Color.primary)
                    .frame(width: isSearchExpanded ? nil : height, height: height)
                    .onTapGesture {
                        withAnimation(.bouncy) {
                            isSearchExpanded = true
                        }
                    }
                    .allowsHitTesting(!isSearchExpanded)

                if isSearchExpanded {
                    TextField("Search...", text: $searchText)
                        .focused($isKeyboardActive)
                }
            }
            .padding(.horizontal, isSearchExpanded ? 15 : 0)
            .background(tabBarBackground())
            .optionalGeometryGroup()
            .zIndex(1)

            /// Close Button
            Button {
                isKeyboardActive = false
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(Color.primary)
                    .frame(width: height, height: height)
                    .background(tabBarBackground())
            }
            /// Only Showing when keyboard is active
            .opacity(isKeyboardActive ? 1 : 0)
        }
    }

    var accentColor: Color {
        return .blue
    }
}

#Preview {
    ContentView()
        .environmentObject(ViewModelFactory())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
