//
//  CustomSegmentedControl.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/28
//
//

import SwiftUI
import UIKit

struct CustomSegmentedControl: UIViewRepresentable {

    @Binding var selection: TransactionType
    var size: CGSize

    // allCasesを配列として保持し、インデックスとcaseを安全に対応させる
    private var cases: [TransactionType] { Array(TransactionType.allCases) }

    func makeUIView(context: Context) -> UISegmentedControl {
        let titles = cases.map { $0.rawValue }
        // itemsが空だとクラッシュするためガード
        guard !titles.isEmpty else {
            return UISegmentedControl()
        }

        let control = UISegmentedControl(items: titles)
        if let index = cases.firstIndex(of: selection) {
            control.selectedSegmentIndex = index
        }

        for (index, content) in cases.enumerated() {
            let renderer = ImageRenderer(
                content:
                    HStack {
                        Image(systemName: "\(content.imageName)")
                        Text("\(content.rawValue)")
                    }
            )
            renderer.scale = 2
            let image = renderer.uiImage

            control.setImage(image, forSegmentAt: index)
        }
        control.addTarget(
            context.coordinator,
            action: #selector(Coordinator.valueChanged(_:)),
            for: .valueChanged
        )
        return control
    }

    func updateUIView(_ uiView: UISegmentedControl, context: Context) {
        context.coordinator.parent = self
        guard let index = cases.firstIndex(of: selection),
            index < uiView.numberOfSegments
        else { return }
        if uiView.selectedSegmentIndex != index {
            uiView.selectedSegmentIndex = index
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UISegmentedControl,
        context: Context
    ) -> CGSize? {
        return size
    }

    final class Coordinator: NSObject {
        var parent: CustomSegmentedControl

        init(_ parent: CustomSegmentedControl) {
            self.parent = parent
        }

        @MainActor @objc func valueChanged(_ sender: UISegmentedControl) {
            let cases = parent.cases
            guard sender.selectedSegmentIndex < cases.count else { return }
            parent.selection = cases[sender.selectedSegmentIndex]
        }
    }
}

#Preview {
    let viewModelFactory = ViewModelFactory()

    return HomeView(
        homeViewModel: viewModelFactory.homeViewModel,
        searchViewModel: viewModelFactory.searchViewModel,
        transactionInputViewModel: viewModelFactory.transactionInputViewModel
    )
}
