//
//  SharedModels.swift
//  Poem of the Day
//
//  Created by Claude on 2025-01-01.
//
//  DOCUMENTATION: Shared Code Framework Guide
//
//  This file documents the models and code that should be shared between
//  the main app target and the widget target. Currently, these are duplicated.
//
//  RECOMMENDED: Create a shared framework called "PoemCore" or use Swift Package Manager
//
//  Steps to create shared framework:
//  1. File > New > Target > Framework
//  2. Name it "PoemCore"
//  3. Move shared files to the framework
//  4. Add framework to both app and widget targets
//  5. Import PoemCore where needed
//

import Foundation

// MARK: - Shared Models (Currently Duplicated)
//
// The following models are currently duplicated in both targets:
// - Poem / WidgetPoem
// - PoemResponse / WidgetPoemResponse
// - DailyVibe
// - PoemError
// - AppConfiguration.Storage (for app group identifier)
//
// These should be consolidated into a shared framework.

// MARK: - Shared Constants

/// Constants shared between app and widget
enum SharedConstants {
    /// App Group identifier for sharing data
    static let appGroupIdentifier = "group.com.stevereitz.poemoftheday"
    
    /// UserDefaults keys
    enum UserDefaultsKeys {
        static let poemTitle = "poemTitle"
        static let poemContent = "poemContent"
        static let poemAuthor = "poemAuthor"
        static let poemVibe = "poemVibe"
        static let poemSource = "poemSource"
        static let lastPoemFetchDate = "lastPoemFetchDate"
        static let lastVibeAnalysisDate = "lastVibeAnalysisDate"
        static let cachedVibeAnalysis = "cachedVibeAnalysis"
        static let favoritePoems = "favoritePoems"
        static let poemHistory = "poemHistory"
        static let notificationSettings = "notificationSettings"
    }
    
    enum NotificationIdentifiers {
        static let dailyPoem = "daily_poem_notification"
        static let poemReminder = "poem_reminder"
        static let category = "DAILY_POEM"
    }
}

/// Unified availability status for AI features
public enum AIAvailabilityStatus: String, Codable {
    case available
    case notEligible
    case notEnabled
    case loading
    case unavailable
    
    public var isAvailable: Bool { self == .available }
    
    public var userMessage: String {
        switch self {
        case .available: return "Available"
        case .notEligible: return "Not supported on this device"
        case .notEnabled: return "Enable in Settings > Apple Intelligence"
        case .loading: return "Downloading AI models..."
        case .unavailable: return "Unavailable"
        }
    }
}

// MARK: - Unified Poem Model (For Future Shared Framework)
//
// When creating the shared framework, use this unified model:
//
// public struct SharedPoem: Identifiable, Codable, Equatable {
//     public let id: UUID
//     public let title: String
//     public let content: String
//     public let author: String?
//     public let vibe: DailyVibe?
//
//     public init(id: UUID = UUID(), title: String, lines: [String], author: String? = nil, vibe: DailyVibe? = nil) {
//         self.id = id
//         self.title = title
//         self.content = lines.joined(separator: "\n")
//         self.author = author?.isEmpty == true ? nil : author
//         self.vibe = vibe
//     }
//
//     public var shareText: String {
//         var text = title
//         if let author = author {
//             text += "\nby \(author)"
//         }
//         text += "\n\n\(content)"
//         return text
//     }
//
//     public var lines: [String] {
//         content.components(separatedBy: "\n")
//     }
// }

// MARK: - Widget Data Transfer

/// Helper for transferring data between app and widget via UserDefaults
struct WidgetDataTransfer {
    private let userDefaults: UserDefaults?
    
    init() {
        self.userDefaults = UserDefaults(suiteName: SharedConstants.appGroupIdentifier)
    }
    
    /// Save poem data for widget access
    func savePoem(_ poem: Poem) {
        userDefaults?.set(poem.title, forKey: SharedConstants.UserDefaultsKeys.poemTitle)
        userDefaults?.set(poem.content, forKey: SharedConstants.UserDefaultsKeys.poemContent)
        userDefaults?.set(poem.author ?? "", forKey: SharedConstants.UserDefaultsKeys.poemAuthor)
        
        if let vibe = poem.vibe {
            userDefaults?.set(vibe.rawValue, forKey: SharedConstants.UserDefaultsKeys.poemVibe)
        } else {
            userDefaults?.removeObject(forKey: SharedConstants.UserDefaultsKeys.poemVibe)
        }
        
        userDefaults?.set(Date(), forKey: SharedConstants.UserDefaultsKeys.lastPoemFetchDate)
    }
    
    /// Load poem data from widget storage
    func loadPoem() -> Poem? {
        guard let title = userDefaults?.string(forKey: SharedConstants.UserDefaultsKeys.poemTitle),
              let content = userDefaults?.string(forKey: SharedConstants.UserDefaultsKeys.poemContent) else {
            return nil
        }
        
        let author = userDefaults?.string(forKey: SharedConstants.UserDefaultsKeys.poemAuthor)
        let vibeRawValue = userDefaults?.string(forKey: SharedConstants.UserDefaultsKeys.poemVibe)
        let vibe = vibeRawValue.flatMap { DailyVibe(rawValue: $0) }
        
        return Poem(
            title: title,
            lines: content.components(separatedBy: "\n"),
            author: author?.isEmpty == true ? nil : author,
            vibe: vibe
        )
    }
    
    /// Check if we need to fetch a new poem
    func shouldFetchNewPoem() -> Bool {
        guard let lastFetchDate = userDefaults?.object(forKey: SharedConstants.UserDefaultsKeys.lastPoemFetchDate) as? Date else {
            return true
        }
        return !Calendar.current.isDate(lastFetchDate, inSameDayAs: Date())
    }
}

// MARK: - Future Framework Contents
//
// The shared framework should include:
//
// Models/
//   - SharedPoem.swift (unified Poem model)
//   - DailyVibe.swift
//   - PoemError.swift
//   - VibeModels.swift (VibeAnalysis, SentimentScore, etc.)
//
// Core/
//   - SharedConstants.swift
//   - WidgetDataTransfer.swift
//
// Extensions/
//   - Date+Extensions.swift
//   - String+Extensions.swift
//
// This would eliminate the current duplication and ensure
// consistency between the app and widget.
