import Foundation
import OSLog

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

// MARK: - Specific Event Types

struct PoemFetchEvent: TelemetryEvent {
    let eventName: String = "poem_fetch"
    let timestamp: Date
    let source: TelemetrySource
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
    let eventName: String = "favorite_action"
    let timestamp: Date
    let source: TelemetrySource
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
    let eventName: String = "share_action"
    let timestamp: Date
    let source: TelemetrySource
    let poemSource: String
    
    var parameters: [String: TelemetryValue] {
        [
            "poem_source": .string(poemSource)
        ]
    }
}

struct AIGenerationEvent: TelemetryEvent {
    let eventName: String = "ai_generation"
    let timestamp: Date
    let source: TelemetrySource
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
    let eventName: String = "app_launch"
    let timestamp: Date
    let source: TelemetrySource = .mainApp
    let launchType: LaunchType
    let coldStart: Bool
    let aiAvailable: Bool
    
    enum LaunchType: String, Codable {
        case normal = "normal"
        case background = "background"
        case fromWidget = "from_widget"
    }
    
    var parameters: [String: TelemetryValue] {
        [
            "launch_type": .string(launchType.rawValue),
            "cold_start": .bool(coldStart),
            "ai_available": .bool(aiAvailable)
        ]
    }
}

struct WidgetInteractionEvent: TelemetryEvent {
    let eventName: String = "widget_interaction"
    let timestamp: Date
    let source: TelemetrySource = .widget
    let interactionType: WidgetInteraction
    let widgetFamily: String
    
    enum WidgetInteraction: String, Codable {
        case view = "view"
        case tap = "tap"
        case refresh = "refresh"
    }
    
    var parameters: [String: TelemetryValue] {
        [
            "interaction_type": .string(interactionType.rawValue),
            "widget_family": .string(widgetFamily)
        ]
    }
}

struct ErrorEvent: TelemetryEvent {
    let eventName: String = "error_occurred"
    let timestamp: Date
    let source: TelemetrySource
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
}

// MARK: - Telemetry Service Actor

actor TelemetryService: TelemetryServiceProtocol {
    private var configuration: TelemetryConfiguration
    private var eventQueue: [TelemetryEvent] = []
    private let userDefaults: UserDefaults
    private let logger: AppLogger
    private var lastFlushDate: Date = Date()
    private var flushTimer: Timer?
    
    init(
        configuration: TelemetryConfiguration = .default,
        userDefaults: UserDefaults = UserDefaults(suiteName: AppConfiguration.appGroupIdentifier) ?? .standard,
        logger: AppLogger = .shared
    ) {
        self.configuration = configuration
        self.userDefaults = userDefaults
        self.logger = logger
        
        Task {
            await loadPersistedEvents()
            await schedulePeriodicFlush()
        }
    }
    
    deinit {
        flushTimer?.invalidate()
    }
    
    func configure(with configuration: TelemetryConfiguration) async {
        self.configuration = configuration
        logger.info("Telemetry configuration updated", category: .general)
        
        if !configuration.isEnabled {
            await clearAllEvents()
        }
    }
    
    func isEnabled() async -> Bool {
        return configuration.isEnabled
    }
    
    func getEventCount() async -> Int {
        return eventQueue.count
    }
    
    func track(_ event: TelemetryEvent) async {
        guard configuration.isEnabled else { return }
        guard configuration.enabledCategories.contains(event.eventName) else { return }
        
        eventQueue.append(event)
        logger.debug("Tracked event: \(event.eventName)", category: .telemetry)
        
        if eventQueue.count >= configuration.batchSize {
            await flush()
        }
    }
    
    func flush() async {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToFlush = eventQueue
        eventQueue.removeAll()
        
        await persistEvents(eventsToFlush)
        await cleanupOldEvents()
        
        lastFlushDate = Date()
        logger.info("Flushed \(eventsToFlush.count) telemetry events", category: .telemetry)
    }
    
    private func persistEvents(_ events: [TelemetryEvent]) async {
        let eventData = events.compactMap { event in
            try? JSONEncoder().encode(AnyTelemetryEvent(event))
        }
        
        var existingEvents = userDefaults.array(forKey: "telemetry_events") as? [Data] ?? []
        existingEvents.append(contentsOf: eventData)
        
        userDefaults.set(existingEvents, forKey: "telemetry_events")
    }
    
    private func loadPersistedEvents() async {
        guard let eventDataArray = userDefaults.array(forKey: "telemetry_events") as? [Data] else { return }
        
        let events = eventDataArray.compactMap { data in
            try? JSONDecoder().decode(AnyTelemetryEvent.self, from: data)
        }
        
        logger.info("Loaded \(events.count) persisted telemetry events", category: .telemetry)
    }
    
    private func cleanupOldEvents() async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(configuration.retentionDays * 24 * 60 * 60))
        
        guard let eventDataArray = userDefaults.array(forKey: "telemetry_events") as? [Data] else { return }
        
        let filteredEvents = eventDataArray.compactMap { data -> Data? in
            guard let event = try? JSONDecoder().decode(AnyTelemetryEvent.self, from: data) else { return nil }
            return event.timestamp > cutoffDate ? data : nil
        }
        
        userDefaults.set(filteredEvents, forKey: "telemetry_events")
        
        let removedCount = eventDataArray.count - filteredEvents.count
        if removedCount > 0 {
            logger.info("Cleaned up \(removedCount) old telemetry events", category: .telemetry)
        }
    }
    
    private func clearAllEvents() async {
        eventQueue.removeAll()
        userDefaults.removeObject(forKey: "telemetry_events")
        logger.info("All telemetry events cleared", category: .telemetry)
    }
    
    private func schedulePeriodicFlush() async {
        DispatchQueue.main.async { [weak self] in
            self?.flushTimer = Timer.scheduledTimer(withTimeInterval: self?.configuration.flushInterval ?? 300, repeats: true) { _ in
                Task { [weak self] in
                    await self?.flush()
                }
            }
        }
    }
}

// MARK: - Mock Implementation for Testing

final class MockTelemetryService: TelemetryServiceProtocol, @unchecked Sendable {
    private var trackedEvents: [TelemetryEvent] = []
    private var _isEnabled = true
    
    func track(_ event: TelemetryEvent) async {
        trackedEvents.append(event)
    }
    
    func flush() async {
        // Mock implementation - events are kept in memory
    }
    
    func configure(with configuration: TelemetryConfiguration) async {
        _isEnabled = configuration.isEnabled
    }
    
    func isEnabled() async -> Bool {
        return _isEnabled
    }
    
    func getEventCount() async -> Int {
        return trackedEvents.count
    }
    
    // Test helper methods
    func getTrackedEvents() -> [TelemetryEvent] {
        return trackedEvents
    }
    
    func clearTrackedEvents() {
        trackedEvents.removeAll()
    }
    
    func getEventsOfType<T: TelemetryEvent>(_ type: T.Type) -> [T] {
        return trackedEvents.compactMap { $0 as? T }
    }
}