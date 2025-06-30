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
    var eventName: String = "widget_interaction"
    let timestamp: Date
    var source: TelemetrySource = .widget
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
        isEnabled: true, // Assuming debug mode is handled elsewhere for widget
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

// MARK: - Telemetry Service Actor

actor TelemetryService: TelemetryServiceProtocol {
    private var configuration: TelemetryConfiguration
    private var eventQueue: [TelemetryEvent] = []
    private let userDefaults: UserDefaults
    private let logger: OSLog
    private var lastFlushDate: Date = Date()
    private var flushTask: Task<Void, Never>?
    
    init(
        configuration: TelemetryConfiguration = .default,
        userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.stevereitz.poemoftheday") ?? .standard,
        logger: OSLog = OSLog(subsystem: "com.stevereitz.poemoftheday", category: "Telemetry")
    ) {
        self.configuration = configuration
        self.userDefaults = userDefaults
        self.logger = logger
        
        self.flushTask = Task {
            await loadPersistedEvents()
            await schedulePeriodicFlush()
        }
    }
    
    deinit {
        flushTask?.cancel()
    }
    
    func configure(with configuration: TelemetryConfiguration) async {
        self.configuration = configuration
        os_log("Telemetry configuration updated", log: logger, type: .info)
        
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
    
    func exportAllEvents() async -> [AnyTelemetryEvent] {
        // Get queued events
        var allEvents = eventQueue.map { AnyTelemetryEvent($0) }
        
        // Get persisted events
        if let eventDataArray = userDefaults.array(forKey: "telemetry_events") as? [Data] {
            let persistedEvents = eventDataArray.compactMap { data in
                try? JSONDecoder().decode(AnyTelemetryEvent.self, from: data)
            }
            allEvents.append(contentsOf: persistedEvents)
        }
        
        // Sort by timestamp
        return allEvents.sorted { $0.timestamp < $1.timestamp }
    }
    
    func exportEventsAsJSON() async -> String? {
        let events = await exportAllEvents()
        guard let jsonData = try? JSONEncoder().encode(events) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    func getEventSummary() async -> TelemetryEventSummary {
        let events = await exportAllEvents()
        
        var summary = TelemetryEventSummary()
        
        for event in events {
            summary.totalEvents += 1
            summary.eventCounts[event.eventName, default: 0] += 1
            
            // Track source breakdown
            summary.sourceBreakdown[event.source.rawValue, default: 0] += 1
        }
        
        summary.dateRange = events.isEmpty ? nil : (
            start: events.first?.timestamp ?? Date(),
            end: events.last?.timestamp ?? Date()
        )
        
        return summary
    }
    
    func track(_ event: TelemetryEvent) async {
        guard configuration.isEnabled else { return }
        guard configuration.enabledCategories.contains(event.eventName) else { return }
        
        eventQueue.append(event)
        os_log("Tracked event: %{public}@", log: logger, type: .debug, event.eventName)
        
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
        os_log("Flushed %d telemetry events", log: logger, type: .info, eventsToFlush.count)
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
        
        os_log("Loaded %d persisted telemetry events", log: logger, type: .info, events.count)
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
            os_log("Cleaned up %d old telemetry events", log: logger, type: .info, removedCount)
        }
    }
    
    private func clearAllEvents() async {
        eventQueue.removeAll()
        userDefaults.removeObject(forKey: "telemetry_events")
        os_log("All telemetry events cleared", log: logger, type: .info)
    }
    
    private func schedulePeriodicFlush() async {
        flushTask?.cancel() // Cancel any previous task before starting a new one

        flushTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(configuration.flushInterval))
                    await flush()
                } catch {
                    // Task was cancelled or other error
                    os_log("Telemetry flush task interrupted: %{public}@", log: logger, type: .error, error.localizedDescription)
                    break
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
    
    func getEventSummary() async -> TelemetryEventSummary {
        return TelemetryEventSummary() // Mock implementation
    }
    
    func exportAllEvents() async -> [AnyTelemetryEvent] {
        return [] // Mock implementation
    }
    
    func exportEventsAsJSON() async -> String? {
        return nil // Mock implementation
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
