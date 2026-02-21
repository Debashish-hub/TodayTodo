//
//  TodayTodoApp.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import SwiftUI

@main
struct TodayTodoApp: App {

    init() {
        // Skip notification permission when running as test host to avoid malloc crash in UNUserNotificationCenter
        if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil {
            NotificationManager.shared.requestPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            let store = FileTaskStore()
            let dateProvider = SystemDateProvider()
            let viewModel = TodayTodoApp.makeViewModel(store: store, dateProvider: dateProvider)
            TaskListView(viewModel: viewModel)
        }
    }

    /// Use no-op dependencies when running as test host so we never touch NotificationManager/WidgetKit/UIKit.
    private static func makeViewModel(store: TaskStoring, dateProvider: DateProviding) -> TaskListViewModel {
        let isTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        if isTestHost {
            return TaskListViewModel(
                store: store,
                dateProvider: dateProvider,
                notificationScheduler: NoOpNotificationScheduler(),
                widgetReloader: NoOpWidgetReloader(),
                hapticFeedback: NoOpHapticFeedback()
            )
        }
        return TaskListViewModel(
            store: store,
            dateProvider: dateProvider,
            notificationScheduler: NotificationManager.shared,
            widgetReloader: SystemWidgetReloader(),
            hapticFeedback: SystemHapticFeedback()
        )
    }
}
