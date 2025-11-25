//
//  PoemHistoryEntry.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-07-04.
//

import Foundation

/// This file is deprecated - PoemHistoryEntry is now defined in PoemHistory.swift
/// with a more complete implementation including source, vibeAtTime, etc.
/// This file can be safely deleted.

/*
/// Minimal struct to make tests compile - following TDD Red phase
struct PoemHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    let poem: Poem
    let dateViewed: Date
    var isFavorite: Bool
    
    init(poem: Poem, dateViewed: Date, isFavorite: Bool = false) {
        self.id = UUID()
        self.poem = poem
        self.dateViewed = dateViewed
        self.isFavorite = isFavorite
    }
    
    // Custom Equatable implementation that excludes the ID
    static func == (lhs: PoemHistoryEntry, rhs: PoemHistoryEntry) -> Bool {
        return lhs.poem == rhs.poem &&
               lhs.dateViewed == rhs.dateViewed &&
               lhs.isFavorite == rhs.isFavorite
    }
}
*/