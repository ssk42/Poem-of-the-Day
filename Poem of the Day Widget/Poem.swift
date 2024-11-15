//
//  PoemResponse.swift
//  Poem of the Day
//
//  Created by Stephen Reitz on 11/15/24.
//


import Foundation

struct PoemResponse: Codable {
    let title: String
    let lines: [String]

    func toPoem() -> Poem {
        return Poem(title: title, lines: lines)
    }
}

struct Poem: Identifiable, Codable {
    let id: UUID?
    let title: String
    let content: String

    init(id: UUID? = UUID(), title: String, lines: [String]) {
        self.id = id
        self.title = title
        self.content = lines.joined(separator: "\n")
    }
}