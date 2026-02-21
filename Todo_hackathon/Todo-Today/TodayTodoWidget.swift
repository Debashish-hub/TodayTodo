//
//  TodayTodoWidget.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//

import SwiftUI
import WidgetKit


@main
struct TodayTodoWidget: Widget {

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "TodayTodoWidget",
            provider: Provider()
        ) { entry in
            TodayTodoWidgetView(entry: entry)
        }
        .configurationDisplayName("Today Tasks")
        .description("Quick view of today's tasks")
    }
}
