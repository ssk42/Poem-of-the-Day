//
//  AppConfiguration.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//

import Foundation

/// Centralized configuration for the app
public enum AppConfiguration {
    
    // MARK: - App Information
    
    public static let appName = "Poem of the Day"
    public static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    public static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    // MARK: - Feature Flags
    
    public enum FeatureFlags {
        public static let aiPoemGeneration = true
        public static let vibeAnalysis = true
        public static let newsIntegration = true
        public static let widgetSupport = true
    }
    
    // MARK: - AI Configuration
    
    public enum AI {
        public static let maxDailyGenerations = 10
        public static let quotaResetInterval: TimeInterval = 24 * 60 * 60 // 24 hours
        public static let minimumIOSVersion = "18.1"
        public static let defaultTemperature = 0.8
    }
    
    // MARK: - News Configuration
    
    public enum News {
        public static let maxArticlesPerSource = 5
        public static let totalArticleLimit = 20
        public static let cacheExpirationTime: TimeInterval = 3 * 60 * 60 // 3 hours
        public static let rssSources = [
            "https://feeds.bbci.co.uk/news/rss.xml",
            "https://feeds.npr.org/1001/rss.xml",
            "https://feeds.apnews.com/rss/apf-topnews",
            "https://feeds.reuters.com/reuters/worldNews",
            "http://rss.cnn.com/rss/edition.rss"
        ]
    }
    
    // MARK: - Storage Configuration
    
    public enum Storage {
        public static let appGroupIdentifier = "group.com.stevereitz.poemoftheday"
        public static let maxFavoritePoems = 100
        public static let cacheVersionKey = "cacheVersion"
        public static let currentCacheVersion = 2
    }
    
    // MARK: - UI Configuration
    
    public enum UI {
        public static let animationDuration = 0.3
        public static let hapticFeedbackEnabled = true
        public static let maxPoemDisplayLines = 20
        public static let cardCornerRadius: CGFloat = 16
        public static let buttonCornerRadius: CGFloat = 12
    }
    
    // MARK: - Network Configuration
    
    public enum Network {
        public static let requestTimeout: TimeInterval = 30
        public static let maxRetryAttempts = 3
        public static let retryDelay: TimeInterval = 1.0
    }
    
    // MARK: - Debug Configuration
    
    public enum Debug {
        #if DEBUG
        public static let isDebugMode = true
        public static let enableLogging = true
        public static let useSimulatedData = false
        #else
        public static let isDebugMode = false
        public static let enableLogging = false
        public static let useSimulatedData = false
        #endif
    }
    
    // MARK: - Testing Configuration
    
    public enum Testing {
        public static var isUITesting: Bool {
            let processInfo = ProcessInfo.processInfo
            let args = processInfo.arguments
            let env = processInfo.environment
            return args.contains("--ui-testing")
                || args.contains("-UITESTING")
                || env["UITESTING"] == "1"
                || UserDefaults.standard.bool(forKey: "UITESTING")
                || env["XCTestConfigurationFilePath"] != nil
        }
        
        public static var isAIAvailable: Bool {
            if isUITesting {
                return ProcessInfo.processInfo.environment["AI_AVAILABLE"] != "false"
            }
            return FeatureFlags.aiPoemGeneration
        }
        
        public static var shouldMockAIResponses: Bool {
            isUITesting && ProcessInfo.processInfo.environment["MOCK_AI_RESPONSES"] == "true"
        }
        
        public static var shouldSimulateNetworkError: Bool {
            isUITesting && ProcessInfo.processInfo.environment["SIMULATE_NETWORK_ERROR"] == "true"
        }
        
        public static var shouldMockAIError: Bool {
            isUITesting && ProcessInfo.processInfo.environment["MOCK_AI_ERROR"] == "true"
        }
        
        public static var enableTelemetryTesting: Bool {
            isUITesting && ProcessInfo.processInfo.environment["ENABLE_TELEMETRY"] == "true"
        }
    }
}

// MARK: - Environment Detection

extension AppConfiguration {
    
    public static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }
    
    public static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    public static var isTestEnvironment: Bool {
        NSClassFromString("XCTestCase") != nil
    }
    
    public static var isUITestEnvironment: Bool {
        Testing.isUITesting
    }
}
