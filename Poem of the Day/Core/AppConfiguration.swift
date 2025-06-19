//
//  AppConfiguration.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

/// Centralized configuration for the app
enum AppConfiguration {
    
    // MARK: - App Information
    
    static let appName = "Poem of the Day"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    
    enum FeatureFlags {
        static let aiPoemGeneration = true
        static let vibeAnalysis = true
        static let newsIntegration = true
        static let widgetSupport = true
    }
    
    // MARK: - AI Configuration
    
    enum AI {
        static let maxDailyGenerations = 10
        static let quotaResetInterval: TimeInterval = 24 * 60 * 60 // 24 hours
        static let minimumIOSVersion = "18.1"
        static let defaultTemperature = 0.8
    }
    
    // MARK: - News Configuration
    
    enum News {
        static let maxArticlesPerSource = 5
        static let totalArticleLimit = 20
        static let cacheExpirationTime: TimeInterval = 3 * 60 * 60 // 3 hours
        static let rssSources = [
            "https://feeds.bbci.co.uk/news/rss.xml",
            "https://feeds.npr.org/1001/rss.xml",
            "https://feeds.apnews.com/rss/apf-topnews",
            "https://feeds.reuters.com/reuters/worldNews",
            "http://rss.cnn.com/rss/edition.rss"
        ]
    }
    
    // MARK: - Storage Configuration
    
    enum Storage {
        static let appGroupIdentifier = "group.com.stevereitz.poemoftheday"
        static let maxFavoritePoems = 100
        static let cacheVersionKey = "cacheVersion"
        static let currentCacheVersion = 2
    }
    
    // MARK: - UI Configuration
    
    enum UI {
        static let animationDuration = 0.3
        static let hapticFeedbackEnabled = true
        static let maxPoemDisplayLines = 20
        static let cardCornerRadius: CGFloat = 16
        static let buttonCornerRadius: CGFloat = 12
    }
    
    // MARK: - Network Configuration
    
    enum Network {
        static let requestTimeout: TimeInterval = 30
        static let maxRetryAttempts = 3
        static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Debug Configuration
    
    enum Debug {
        #if DEBUG
        static let isDebugMode = true
        static let enableLogging = true
        static let useSimulatedData = false
        #else
        static let isDebugMode = false
        static let enableLogging = false
        static let useSimulatedData = false
        #endif
    }
}

// MARK: - Environment Detection

extension AppConfiguration {
    
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    static var isTestEnvironment: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}