//
//  TodayTodoWidgetView.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//
import SwiftUI
import WidgetKit

struct TodayTodoWidgetView: View {

    let entry: TaskEntry

    var pendingTasks: [TaskItem] {
        entry.tasks.filter { !$0.isCompleted }
    }

    var body: some View {
        content
            .applyWidgetBackground()
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 10) {

            // Header
            HStack {
                Text("Today")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Text("\(pendingTasks.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            if pendingTasks.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)

                    Text("All done 🎉")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(pendingTasks.prefix(3)) { task in
                        HStack(spacing: 6) {
                            Circle()
                                .frame(width: 6, height: 6)
                                .foregroundStyle(.tint)

                            Text(task.title)
                                .font(.caption)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}


extension View {
    @ViewBuilder
    func applyWidgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(.fill.tertiary, for: .widget)
        } else {
            self.background(Color(.systemBackground))
        }
    }
}
