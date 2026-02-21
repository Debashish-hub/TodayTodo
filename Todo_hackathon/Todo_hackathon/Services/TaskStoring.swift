//
//  TaskStoring.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//


import Foundation

protocol TaskStoring {
    func load() -> [TaskItem]
    func save(_ tasks: [TaskItem])
}

