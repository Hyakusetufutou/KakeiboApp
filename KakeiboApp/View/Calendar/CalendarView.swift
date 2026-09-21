//
//  CalendarView.swift
//  KakeiboApp
//
//  Created by Hyakusetufutou on 2025/10/02
//
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var calendarViewModel: CalendarViewModel
    @ObservedObject var transactionInputViewModel: TransactionInputViewModel

    init(
        calendarViewModel: CalendarViewModel,
        transactionInputViewModel: TransactionInputViewModel
    ) {
        self.calendarViewModel = calendarViewModel
        self.transactionInputViewModel = transactionInputViewModel
    }

    var body: some View {
        NavigationStack {

            List {
                monthNavigationView

                CalendarGridView(calendarViewModel: calendarViewModel)

                CalendarSelectedDateContentView(
                    calendarViewModel: calendarViewModel,
                    transactionInputViewModel: transactionInputViewModel
                )
            }
            .padding(.horizontal, 16)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .background(AppTheme.background)
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                Task {
                    await calendarViewModel.reload()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("今日") {
                        calendarViewModel.goToToday()
                    }
                }
            }
            .overlay {
                if calendarViewModel.isLoading && calendarViewModel.dailySummaries.isEmpty {
                    ProgressView("読み込み中...")
                        .padding()
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("エラー", isPresented: errorAlertBinding) {
                Button("OK") {
                    calendarViewModel.clearError()
                }
            } message: {
                if let errorMessage = calendarViewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }

    // MARK: - Month Navigation

    private var monthNavigationView: some View {
        ChangeMonthView(
            date: $calendarViewModel.dateRange.start,
            onPreviousMonth: {
                calendarViewModel.changeMonth(by: -1)
            },
            onNextMonth: {
                calendarViewModel.changeMonth(by: 1)
            }
        )
        .listRowSeparatorHiddenAndBackgroundClear()
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { calendarViewModel.errorMessage != nil },
            set: { if !$0 { calendarViewModel.clearError() } }
        )
    }
}
