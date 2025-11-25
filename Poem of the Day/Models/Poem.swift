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

struct Poem: Identifiable, Codable, Equatable {
    enum Source: String, Codable {
        case api
        case aiGenerated
        case localFallback
    }
    
    let id: UUID
    let title: String
    let content: String
    let author: String?
    let vibe: DailyVibe?
    let source: Source?

    init(id: UUID = UUID(), title: String, lines: [String], author: String? = nil, vibe: DailyVibe? = nil, source: Source? = nil) {
        self.id = id
        self.title = title
        self.content = lines.joined(separator: "\n")
        self.author = author?.isEmpty == true ? nil : author
        self.vibe = vibe
        self.source = source
    }
    
    var shareText: String {
        var text = title
        if let author = author {
            text += "\nby \(author)"
        }
        text += "\n\n\(content)"
        return text
    }
}

