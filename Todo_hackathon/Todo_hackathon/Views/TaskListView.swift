//
//  TaskListView.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import SwiftUI

struct TaskListView: View {

    @StateObject var viewModel: TaskListViewModel
    @State private var showAdd = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.tasks.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "sun.max")
                            .font(.largeTitle)
                        Text("A Fresh Start")
                            .font(.headline)
                        Text("Tasks reset every day.\nAdd something to focus on today.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.tasks) { task in
                            TaskRowView(task: task) {
                                withAnimation(.spring()) {
                                    viewModel.toggle(task)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Today's Tasks")
            .toolbar {
                Button {
                    showAdd = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAdd) {
                AddTaskView { title, expiresAt in
                    viewModel.addTask(title: title, expiresAt: expiresAt)
                }
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                )
            ) { _ in
                viewModel.removeExpiredDayTasks()
                viewModel.removeIndividuallyExpiredTasks()
            }
        }
    }
}
