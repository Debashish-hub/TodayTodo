//
//  TaskRowView.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import SwiftUI

// MARK: - Task row display logic (testable without SwiftUI)

enum TaskRowLogic {
    /// SF Symbol name for the completion state icon.
    static func iconName(isCompleted: Bool) -> String {
        isCompleted ? "checkmark.circle.fill" : "circle"
    }

    /// Whether the title should show strikethrough.
    static func shouldStrikethrough(isCompleted: Bool) -> Bool {
        isCompleted
    }
}

struct TaskRowView: View {

    let task: TaskItem
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: TaskRowLogic.iconName(isCompleted: task.isCompleted))
                .foregroundColor(.blue)

            Text(task.title)
                .strikethrough(TaskRowLogic.shouldStrikethrough(isCompleted: task.isCompleted))
                .opacity(task.isCompleted ? 0.6 : 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
        .scaleEffect(task.isCompleted ? 0.98 : 1)
        .animation(.easeInOut, value: task.isCompleted)
    }
}
