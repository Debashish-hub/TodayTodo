//
//  AddTaskView.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import SwiftUI

// MARK: - Add Task logic (testable without SwiftUI)

enum AddTaskLogic {
    /// Merges the hour and minute from `time` onto the calendar day of `today`. Used for expiration picker.
    static func mergeTimeWithToday(_ time: Date, calendar: Calendar = .current, today: Date = Date()) -> Date {
        let comps = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(
            bySettingHour: comps.hour ?? 0,
            minute: comps.minute ?? 0,
            second: 0,
            of: today
        ) ?? today
    }

    /// Whether the Add button should be enabled (non-empty title).
    static func canSubmit(title: String) -> Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct AddTaskView: View {

    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var hasExpiration = false
    @State private var time = Date()

    let onAdd: (String, Date?) -> Void

    var body: some View {
        NavigationStack {
            Form {
                TextField("Task title", text: $title)

                Toggle("Set expiration time", isOn: $hasExpiration)

                if hasExpiration {
                    DatePicker(
                        "Expires at",
                        selection: $time,
                        displayedComponents: .hourAndMinute
                    )
                }
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let expires = hasExpiration
                            ? AddTaskLogic.mergeTimeWithToday(time)
                            : nil
                        onAdd(title, expires)
                        dismiss()
                    }
                    .disabled(!AddTaskLogic.canSubmit(title: title))
                }
            }
        }
    }
}
