//
//  Provider.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//
import SwiftUI
import WidgetKit

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry(date: Date(), tasks: [])
    }

    func getSnapshot(in context: Context,
                     completion: @escaping (TaskEntry) -> Void) {

        completion(TaskEntry(
            date: Date(),
            tasks: TaskLoader.loadTasks()
        ))
    }

    func getTimeline(in context: Context,
                     completion: @escaping (Timeline<TaskEntry>) -> Void) {

        let entry = TaskEntry(
            date: Date(),
            tasks: TaskLoader.loadTasks()
        )

        let timeline = Timeline(
            entries: [entry],
            policy: .after(
                Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
            )
        )

        completion(timeline)
    }
}
