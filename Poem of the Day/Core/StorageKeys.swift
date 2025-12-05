//
//  StorageKeys.swift
//  Poem of the Day
//
//  Centralized UserDefaults keys for maintainability
//

import Foundation

/// Centralized storage keys to avoid hardcoded strings throughout the codebase
enum StorageKeys {
    
    // MARK: - Poem Storage
    
    static let poemTitle = "poemTitle"
    static let poemContent = "poemContent"
    static let poemAuthor = "poemAuthor"
    static let poemSource = "poemSource"
    static let poemVibe = "poemVibe"
    static let lastPoemFetchDate = "lastPoemFetchDate"
    
    // MARK: - Favorites
    
    static let favoritePoems = "favoritePoems"
    
    // MARK: - Vibe Analysis
    
    static let cachedVibeAnalysis = "cachedVibeAnalysis"
    static let lastVibeAnalysisDate = "lastVibeAnalysisDate"
    
    // MARK: - History
    
    static let poemHistory = "poemHistory"
    
    // MARK: - Settings
    
    static let preferredPoemSource = "preferredPoemSource"
    
    // MARK: - Telemetry
    
    static let telemetryEvents = "telemetry_events"
    static let widgetTelemetryEvents = "widget_telemetry_events"
    
    // MARK: - Notifications
    
    static let notificationSettings = "notificationSettings"
}

