//
//  Protocols.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
//  Updated with history and notification protocols
//

import Foundation

// MARK: - Service Protocols

/// Protocol for network services
protocol NetworkServiceProtocol: Sendable {
    func fetchRandomPoem() async throws -> Poem
}

/// Protocol for news services
protocol NewsServiceProtocol: Sendable {
    func fetchDailyNews() async throws -> [NewsArticle]
}

/// Protocol for vibe analysis services
protocol VibeAnalyzerProtocol: Sendable {
    func analyzeVibe(from articles: [NewsArticle]) async -> VibeAnalysis
}

/// Protocol for AI poem generation services
protocol PoemGenerationServiceProtocol: Sendable {
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem
    func isAvailable() async -> Bool
    func checkAvailability() async -> AIAvailabilityStatus
}

/// Protocol for poem repository
protocol PoemRepositoryProtocol: Sendable {
    func getDailyPoem() async throws -> Poem
    func refreshDailyPoem() async throws -> Poem
    func generateVibeBasedPoem() async throws -> Poem
    func generateCustomPoem(prompt: String) async throws -> Poem
    func getVibeOfTheDay() async throws -> VibeAnalysis
    func isAIGenerationAvailable() async -> Bool
    func getAIAvailabilityStatus() async -> AIAvailabilityStatus
    func getFavorites() async -> [Poem]
    func addToFavorites(_ poem: Poem) async
    func removeFromFavorites(_ poem: Poem) async
    func isFavorite(_ poem: Poem) async -> Bool
    func getHistory() async -> [PoemHistoryEntry]
    func getHistoryGroupedByDate() async -> [(date: Date, entries: [PoemHistoryEntry])]
    func getStreakInfo() async -> StreakInfo
}

// MARK: - Data Protocols

/// Protocol for identifiable and cacheable data
protocol CacheableData: Codable, Identifiable {
    var cacheKey: String { get }
    var expirationDate: Date? { get }
}

/// Protocol for shareable content
protocol ShareableContent {
    var shareText: String { get }
    var shareTitle: String? { get }
    var shareURL: URL? { get }
}

/// Protocol for content that can be favorited
protocol FavoriteContent: Identifiable {
    var title: String { get }
    var isFavorited: Bool { get }
}

// MARK: - UI Protocols

/// Protocol for view models
protocol ViewModelProtocol: ObservableObject {
    associatedtype State
    var state: State { get }
    func refresh() async
}

/// Protocol for views that can show loading states
protocol LoadingStateView {
    var isLoading: Bool { get }
    var loadingMessage: String? { get }
}

/// Protocol for views that can show error states
protocol ErrorStateView {
    var error: Error? { get }
    var errorMessage: String? { get }
    func handleError(_ error: Error)
    func clearError()
}

// MARK: - Analytics Protocols

/// Protocol for tracking analytics events
protocol AnalyticsTrackable {
    var analyticsEventName: String { get }
    var analyticsParameters: [String: Any] { get }
}

/// Protocol for objects that can be logged
protocol Loggable {
    var logDescription: String { get }
    var logCategory: AppLogger.Category { get }
}

// MARK: - Configuration Protocols

/// Protocol for feature flags
protocol FeatureFlag {
    var isEnabled: Bool { get }
    var description: String { get }
}

/// Protocol for app configuration
protocol ConfigurationProviding {
    func value(for key: String) -> Any?
    func setValue(_ value: Any?, for key: String)
}

// MARK: - Telemetry Event Protocol

protocol TelemetryEvent: Codable, Sendable {
    var eventName: String { get }
    var timestamp: Date { get }
    var parameters: [String: TelemetryValue] { get }
    var source: TelemetrySource { get }
}

enum TelemetrySource: String, Codable, Sendable {
    case mainApp = "main_app"
    case widget = "widget"
}

enum TelemetryValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case date(Date)
    
    var value: Any {
        switch self {
        case .string(let value): return value
        case .int(let value): return value
        case .double(let value): return value
        case .bool(let value): return value
        case .date(let value): return value
        }
    }
}

// MARK: - Type-Erased Event Wrapper

struct AnyTelemetryEvent: Codable {
    let eventName: String
    let timestamp: Date
    let parameters: [String: TelemetryValue]
    let source: TelemetrySource
    
    init(_ event: TelemetryEvent) {
        self.eventName = event.eventName
        self.timestamp = event.timestamp
        self.parameters = event.parameters
        self.source = event.source
    }
}

// MARK: - Telemetry Summary

struct TelemetryEventSummary {
    var totalEvents: Int = 0
    var eventCounts: [String: Int] = [:]
    var sourceBreakdown: [String: Int] = [:]
    var dateRange: (start: Date, end: Date)?
    
    var mostCommonEvent: String? {
        eventCounts.max(by: { $0.value < $1.value })?.key
    }
    
    var averageEventsPerDay: Double {
        guard let dateRange = dateRange else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: dateRange.start, to: dateRange.end).day ?? 1
        return Double(totalEvents) / Double(max(days, 1))
    }
}

// MARK: - Telemetry Configuration

struct TelemetryConfiguration: Codable, Sendable {
    let isEnabled: Bool
    let batchSize: Int
    let flushInterval: TimeInterval
    let retentionDays: Int
    let enabledCategories: Set<String>
    
    static let `default` = TelemetryConfiguration(
        isEnabled: !AppConfiguration.Debug.isDebugMode,
        batchSize: 50,
        flushInterval: 300, // 5 minutes
        retentionDays: 30,
        enabledCategories: [
            "poem_fetch", 
            "favorite_action", 
            "share_action",
            "ai_generation", 
            "app_launch", 
            "widget_interaction", 
            "error_occurred",
            "history_view",
            "notification_scheduled"
        ]
    )
}

// MARK: - Telemetry Service Protocol

protocol TelemetryServiceProtocol: Sendable {
    func track(_ event: TelemetryEvent) async
    func flush() async
    func configure(with configuration: TelemetryConfiguration) async
    func isEnabled() async -> Bool
    func getEventCount() async -> Int
    func getEventSummary() async -> TelemetryEventSummary
    func exportAllEvents() async -> [AnyTelemetryEvent]
    func exportEventsAsJSON() async -> String?
}

// MARK: - Default Implementations

extension AnalyticsTrackable {
    var analyticsParameters: [String: Any] { [:] }
}

extension Loggable {
    var logCategory: AppLogger.Category { .general }
}

// MARK: - Protocol Compositions

/// Combined protocol for complete data models
typealias DataModel = Codable & Identifiable & Equatable

/// Combined protocol for UI state management
typealias UIStateManaging = LoadingStateView & ErrorStateView

/// Combined protocol for content management
typealias ContentManaging = ShareableContent & FavoriteContent

// MARK: - Specific Event Types

struct PoemFetchEvent: TelemetryEvent {
    var eventName: String = "poem_fetch"
    let timestamp: Date
    var source: TelemetrySource
    let poemSource: String
    let duration: TimeInterval
    let success: Bool
    let errorType: String?
    let vibeType: String?
    
    var parameters: [String: TelemetryValue] {
        var params: [String: TelemetryValue] = [
            "poem_source": .string(poemSource),
            "duration": .double(duration),
            "success": .bool(success)
        ]
        
        if let errorType = errorType {
            params["error_type"] = .string(errorType)
        }
        
        if let vibeType = vibeType {
            params["vibe_type"] = .string(vibeType)
        }
        
        return params
    }
}

struct FavoriteActionEvent: TelemetryEvent {
    var eventName: String = "favorite_action"
    let timestamp: Date
    var source: TelemetrySource
    let action: FavoriteAction
    let poemSource: String
    
    enum FavoriteAction: String, Codable {
        case add = "add"
        case remove = "remove"
    }
    
    var parameters: [String: TelemetryValue] {
        [
            "action": .string(action.rawValue),
            "poem_source": .string(poemSource)
        ]
    }
}

struct ShareEvent: TelemetryEvent {
    var eventName: String = "share_action"
    let timestamp: Date
    var source: TelemetrySource
    let poemSource: String
    
    var parameters: [String: TelemetryValue] {
        [
            "poem_source": .string(poemSource)
        ]
    }
}

struct AIGenerationEvent: TelemetryEvent {
    var eventName: String = "ai_generation"
    let timestamp: Date
    var source: TelemetrySource
    let generationType: AIGenerationType
    let duration: TimeInterval
    let success: Bool
    let errorType: String?
    let vibeScore: Double?
    
    enum AIGenerationType: String, Codable {
        case vibeBasedPoem = "vibe_based_poem"
        case customPrompt = "custom_prompt"
        case vibeAnalysis = "vibe_analysis"
    }
    
    var parameters: [String: TelemetryValue] {
        var params: [String: TelemetryValue] = [
            "generation_type": .string(generationType.rawValue),
            "duration": .double(duration),
            "success": .bool(success)
        ]
        
        if let errorType = errorType {
            params["error_type"] = .string(errorType)
        }
        
        if let vibeScore = vibeScore {
            params["vibe_score"] = .double(vibeScore)
        }
        
        return params
    }
}

struct AppLaunchEvent: TelemetryEvent {
    var eventName: String = "app_launch"
    let timestamp: Date
    var source: TelemetrySource = .mainApp
    let launchType: LaunchType
    let coldStart: Bool
    let aiAvailable: Bool
    
    enum LaunchType: String, Codable {
        case normal = "normal"
        case background = "background"
        case fromWidget = "from_widget"
        case fromNotification = "from_notification"
    }
    
    var parameters: [String: TelemetryValue] {
        [
            "launch_type": .string(launchType.rawValue),
            "cold_start": .bool(coldStart),
            "ai_available": .bool(aiAvailable)
        ]
    }
}

struct ErrorEvent: TelemetryEvent {
    var eventName: String = "error_occurred"
    let timestamp: Date
    var source: TelemetrySource
    let errorType: String
    let errorCode: String?
    let context: String
    
    var parameters: [String: TelemetryValue] {
        var params: [String: TelemetryValue] = [
            "error_type": .string(errorType),
            "context": .string(context)
        ]
        
        if let errorCode = errorCode {
            params["error_code"] = .string(errorCode)
        }
        
        return params
    }
}

struct HistoryViewEvent: TelemetryEvent {
    var eventName: String = "history_view"
    let timestamp: Date
    var source: TelemetrySource = .mainApp
    let entryCount: Int
    let currentStreak: Int
    
    var parameters: [String: TelemetryValue] {
        [
            "entry_count": .int(entryCount),
            "current_streak": .int(currentStreak)
        ]
    }
}

struct NotificationEvent: TelemetryEvent {
    var eventName: String = "notification_scheduled"
    let timestamp: Date
    var source: TelemetrySource = .mainApp
    let action: NotificationAction
    let scheduledHour: Int?
    
    enum NotificationAction: String, Codable {
        case enabled = "enabled"
        case disabled = "disabled"
        case rescheduled = "rescheduled"
    }
    
    var parameters: [String: TelemetryValue] {
        var params: [String: TelemetryValue] = [
            "action": .string(action.rawValue)
        ]
        
        if let hour = scheduledHour {
            params["scheduled_hour"] = .int(hour)
        }
        
        return params
    }
}
