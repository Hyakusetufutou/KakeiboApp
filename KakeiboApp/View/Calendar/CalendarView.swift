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
                headerView

                VStack(spacing: 0) {
                    monthNavigationView
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    CalendarGridView(calendarViewModel: calendarViewModel)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                }
                .background(Color(.systemGroupedBackground))

                ScrollView(.vertical, showsIndicators: false) {
                    CalendarSelectedDateContentView(
                        calendarViewModel: calendarViewModel,
                        transactionInputViewModel: transactionInputViewModel
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
                .background(Color(.systemGroupedBackground))
                .refreshable {
                    await calendarViewModel.reload()
                }
            }
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Header & Month Navigation

    private var headerView: some View {
        HStack {
            Text("カレンダー")
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Color(.systemGroupedBackground)
                .shadow(color: Color(.label).opacity(0.08), radius: 2, y: 1)
        }
    }

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
