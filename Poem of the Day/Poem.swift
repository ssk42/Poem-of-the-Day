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
    let author: String

    func toPoem() -> Poem {
        return Poem(title: title, lines: lines, author: author)
    }
}

struct Poem: Identifiable, Codable {
    let id: UUID?
    let title: String
    let content: String
    let author: String?

    init(id: UUID? = UUID(), title: String, lines: [String], author: String = "Unknown") {
        self.id = id
        self.title = title
        self.content = lines.joined(separator: "\n")
        self.author = author
    }
}

