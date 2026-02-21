//
//  NotificationManager.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import UserNotifications

protocol TaskNotificationScheduling: AnyObject {
    func schedule(for task: TaskItem)
    func cancel(for task: TaskItem)
}

// MARK: - Notification content (testable without UNUserNotificationCenter)

struct TaskNotificationContent {
    static let reminderTitle = "Task Reminder"

    let title: String
    let body: String
    let identifier: String
    let dateComponents: DateComponents

    /// Builds notification content from a task. Returns nil if task has no expiry.
    static func from(task: TaskItem, calendar: Calendar = .current) -> TaskNotificationContent? {
        guard let expiresAt = task.expiresAt else { return nil }
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: expiresAt
        )
        return TaskNotificationContent(
            title: reminderTitle,
            body: task.title,
            identifier: task.id.uuidString,
            dateComponents: components
        )
    }
}

final class NotificationManager: TaskNotificationScheduling {

    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func schedule(for task: TaskItem) {
        guard let content = TaskNotificationContent.from(task: task) else { return }

        let unContent = UNMutableNotificationContent()
        unContent.title = content.title
        unContent.body = content.body

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: content.dateComponents,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: content.identifier,
            content: unContent,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancel(for task: TaskItem) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [task.id.uuidString]
            )
    }
}
