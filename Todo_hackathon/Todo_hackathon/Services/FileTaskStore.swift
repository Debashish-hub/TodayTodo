//
//  FileTaskStore.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import Foundation

final class FileTaskStore: TaskStoring {

    private let url: URL = {
            let container = FileManager.default
                .containerURL(forSecurityApplicationGroupIdentifier:
                    "group.com.debashish.todotoday")!

            return container.appendingPathComponent("tasks.json")
        }()

    func load() -> [TaskItem] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([TaskItem].self, from: data)) ?? []
    }

    func save(_ tasks: [TaskItem]) {
        guard let data = try? JSONEncoder().encode(tasks) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
