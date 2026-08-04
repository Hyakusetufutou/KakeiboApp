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
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    monthNavigationView
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    CalendarGridView(calendarViewModel: calendarViewModel)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .background(Color(.systemGroupedBackground))

                CalendarSelectedDateContentView(
                    calendarViewModel: calendarViewModel,
                    transactionInputViewModel: transactionInputViewModel
                )
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("今日") {
                        withAnimation(.snappy) {
                            let today = Date()
                            calendarViewModel.currentDate = today
                            calendarViewModel.selectedDate = today
                        }
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
            date: $calendarViewModel.currentDate,
            onPreviousMonth: {
                calendarViewModel.changeMonth(by: -1)
                calendarViewModel.currentDate =
                    Calendar.current.date(
                        byAdding: .month,
                        value: -1,
                        to: calendarViewModel.currentDate
                    ) ?? calendarViewModel.currentDate
            },
            onNextMonth: {
                calendarViewModel.changeMonth(by: 1)
                calendarViewModel.currentDate =
                    Calendar.current.date(
                        byAdding: .month,
                        value: 1,
                        to: calendarViewModel.currentDate
                    ) ?? calendarViewModel.currentDate
            }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { calendarViewModel.errorMessage != nil },
            set: { if !$0 { calendarViewModel.clearError() } }
        )
    }
}
