//
//  TaskItem.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import Foundation

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    let createdAt: Date
    var expiresAt: Date?
}
