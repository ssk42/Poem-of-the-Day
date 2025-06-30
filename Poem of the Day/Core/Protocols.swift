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
