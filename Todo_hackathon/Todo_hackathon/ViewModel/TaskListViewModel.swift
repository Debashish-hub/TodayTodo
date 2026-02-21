//
//  TaskListViewModel.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import Foundation
import UIKit
import Combine
import WidgetKit

// MARK: - Dependencies (injectable for tests)

protocol WidgetTimelineReloading {
    func reloadAllTimelines()
}

struct SystemWidgetReloader: WidgetTimelineReloading {
    func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}

protocol HapticFeedbackProviding {
    func impactOccurred()
}

struct SystemHapticFeedback: HapticFeedbackProviding {
    func impactOccurred() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// No-op implementations used when running as test host (avoids NotificationManager/WidgetKit/UIKit crash)
final class NoOpNotificationScheduler: TaskNotificationScheduling {
    func schedule(for task: TaskItem) {}
    func cancel(for task: TaskItem) {}
}

struct NoOpWidgetReloader: WidgetTimelineReloading {
    func reloadAllTimelines() {}
}

struct NoOpHapticFeedback: HapticFeedbackProviding {
    func impactOccurred() {}
}

/// True when the process is running as XCTest host (unit tests).
private var isRunningInTests: Bool {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
}

// MARK: - Pure logic (testable without ViewModel / @Published / Combine)

enum TaskListLogic {
    /// Keeps only tasks created on or after the start of `now`'s day.
    static func filterExpiredDayTasks(_ tasks: [TaskItem], now: Date) -> [TaskItem] {
        let todayStart = Calendar.current.startOfDay(for: now)
        return tasks.filter { $0.createdAt >= todayStart }
    }

    /// Keeps only tasks that are not past their individual expiry (or have no expiry).
    static func filterIndividuallyExpired(_ tasks: [TaskItem], now: Date) -> [TaskItem] {
        tasks.filter { task in
            if let expiresAt = task.expiresAt { return expiresAt > now }
            return true
        }
    }

    /// Returns a new array with the given task's `isCompleted` toggled, or nil if not found.
    static func toggleTask(_ task: TaskItem, in tasks: [TaskItem]) -> [TaskItem]? {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return nil }
        var result = tasks
        result[index].isCompleted.toggle()
        return result
    }
}

// MARK: - ViewModel

final class TaskListViewModel: ObservableObject {

    @Published private(set) var tasks: [TaskItem] = []

    private let store: TaskStoring
    private let dateProvider: DateProviding
    private let notificationScheduler: TaskNotificationScheduling
    private let widgetReloader: WidgetTimelineReloading
    private let hapticFeedback: HapticFeedbackProviding

    init(
        store: TaskStoring,
        dateProvider: DateProviding,
        notificationScheduler: TaskNotificationScheduling,
        widgetReloader: WidgetTimelineReloading,
        hapticFeedback: HapticFeedbackProviding
    ) {
        self.store = store
        self.dateProvider = dateProvider
        self.notificationScheduler = notificationScheduler
        self.widgetReloader = widgetReloader
        self.hapticFeedback = hapticFeedback
        load()
        removeExpiredDayTasks()
        removeIndividuallyExpiredTasks()
    }

    func addTask(title: String, expiresAt: Date?) {
        let task = TaskItem(
            id: UUID(),
            title: title,
            isCompleted: false,
            createdAt: dateProvider.now(),
            expiresAt: expiresAt
        )

        tasks.append(task)
        notificationScheduler.schedule(for: task)
        persist()
    }

    func toggle(_ task: TaskItem) {
        guard let newTasks = TaskListLogic.toggleTask(task, in: tasks) else { return }
        tasks = newTasks
        hapticFeedback.impactOccurred()
        if tasks.first(where: { $0.id == task.id })?.isCompleted == true {
            notificationScheduler.cancel(for: task)
        }
        persist()
    }

    func removeExpiredDayTasks() {
        tasks = TaskListLogic.filterExpiredDayTasks(tasks, now: dateProvider.now())
        persist()
    }

    func removeIndividuallyExpiredTasks() {
        tasks = TaskListLogic.filterIndividuallyExpired(tasks, now: dateProvider.now())
        persist()
    }

    private func load() {
        tasks = store.load()
    }

    private func persist() {
        store.save(tasks)
        widgetReloader.reloadAllTimelines()
    }
}
