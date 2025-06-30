//
//  Protocols.swift
//  Poem of the Day
//
//  Created by Claude Code on 2025-06-19.
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
}

/// Protocol for poem repository
protocol PoemRepositoryProtocol: Sendable {
    func getDailyPoem() async throws -> Poem
    func refreshDailyPoem() async throws -> Poem
    func generateVibeBasedPoem() async throws -> Poem
    func generateCustomPoem(prompt: String) async throws -> Poem
    func getVibeOfTheDay() async throws -> VibeAnalysis
    func isAIGenerationAvailable() async -> Bool
    func getFavorites() async -> [Poem]
    func addToFavorites(_ poem: Poem) async
    func removeFromFavorites(_ poem: Poem) async
    func isFavorite(_ poem: Poem) async -> Bool
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
            "error_occurred"
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

// These extensions will be implemented directly in the Poem struct

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