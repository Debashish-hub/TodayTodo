//
//  DateProviding.swift
//  Todo_hackathon
//
//  Created by Debashish on 19/02/26.
//

import SwiftUI

protocol DateProviding {
    func now() -> Date
}

struct SystemDateProvider: DateProviding {
    func now() -> Date { Date() }
}
