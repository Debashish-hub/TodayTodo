//
//  TaskLoader.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import Foundation
import WidgetKit

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [TaskItem]
}

struct TaskLoader {

    static func loadTasks() -> [TaskItem] {

        let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier:
                "group.com.debashish.todotoday")!

        let url = container.appendingPathComponent("tasks.json")

        guard let data = try? Data(contentsOf: url) else { return [] }

        return (try? JSONDecoder()
            .decode([TaskItem].self, from: data)) ?? []
    }
}
