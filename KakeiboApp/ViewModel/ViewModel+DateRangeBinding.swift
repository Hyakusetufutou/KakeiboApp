//
//  ViewModel+DateRangeBinding.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2026/08/04
//
//

import SwiftUI

extension Binding where Value == DateRange {
    var start: Binding<Date> {
        Binding<Date>(
            get: { self.wrappedValue.start },
            set: { self.wrappedValue = self.wrappedValue.withStart($0) }
        )
    }

    var end: Binding<Date> {
        Binding<Date>(
            get: { self.wrappedValue.end },
            set: { self.wrappedValue = self.wrappedValue.withEnd($0) }
        )
    }
}
