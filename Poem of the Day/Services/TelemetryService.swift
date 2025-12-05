import Foundation
import OSLog

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
        userDefaults: UserDefaults = UserDefaults(suiteName: AppConfiguration.Storage.appGroupIdentifier) ?? .standard,
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
    
    func exportAllEvents() async -> [AnyTelemetryEvent] {
        // Get queued events
        var allEvents = eventQueue.map { AnyTelemetryEvent($0) }
        
        // Get persisted events
        if let eventDataArray = userDefaults.array(forKey: StorageKeys.telemetryEvents) as? [Data] {
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
        
        var existingEvents = userDefaults.array(forKey: StorageKeys.telemetryEvents) as? [Data] ?? []
        existingEvents.append(contentsOf: eventData)
        userDefaults.set(existingEvents, forKey: StorageKeys.telemetryEvents)
    }
    
    private func loadPersistedEvents() async {
        guard let eventDataArray = userDefaults.array(forKey: StorageKeys.telemetryEvents) as? [Data] else { return }
        
        let events = eventDataArray.compactMap { data in
            try? JSONDecoder().decode(AnyTelemetryEvent.self, from: data)
        }
        
        logger.info("Loaded \(events.count) persisted telemetry events", category: .telemetry)
    }
    
    private func cleanupOldEvents() async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(configuration.retentionDays * 24 * 60 * 60))
        
        guard let eventDataArray = userDefaults.array(forKey: StorageKeys.telemetryEvents) as? [Data] else { return }
        
        let filteredEvents = eventDataArray.compactMap { data -> Data? in
            guard let event = try? JSONDecoder().decode(AnyTelemetryEvent.self, from: data) else { return nil }
            return event.timestamp > cutoffDate ? data : nil
        }
        
        userDefaults.set(filteredEvents, forKey: StorageKeys.telemetryEvents)
        
        let removedCount = eventDataArray.count - filteredEvents.count
        if removedCount > 0 {
            logger.info("Cleaned up \(removedCount) old telemetry events", category: .telemetry)
        }
    }
    
    private func clearAllEvents() async {
        eventQueue.removeAll()
        userDefaults.removeObject(forKey: StorageKeys.telemetryEvents)
        logger.info("All telemetry events cleared", category: .telemetry)
    }
    
    private func schedulePeriodicFlush() async {
        flushTimer?.invalidate()
        
        // Use a periodic task instead of Timer to avoid main actor issues
        Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self?.configuration.flushInterval ?? 300) * 1_000_000_000)
                await self?.flush()
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
        var summary = TelemetryEventSummary()
        summary.totalEvents = trackedEvents.count
        
        for event in trackedEvents {
            summary.eventCounts[event.eventName, default: 0] += 1
            summary.sourceBreakdown[event.source.rawValue, default: 0] += 1
        }
        
        if !trackedEvents.isEmpty {
            summary.dateRange = (
                start: trackedEvents.first?.timestamp ?? Date(),
                end: trackedEvents.last?.timestamp ?? Date()
            )
        }
        
        return summary
    }
    
    func exportAllEvents() async -> [AnyTelemetryEvent] {
        return trackedEvents.map { AnyTelemetryEvent($0) }
    }
    
    func exportEventsAsJSON() async -> String? {
        let events = await exportAllEvents()
        guard let jsonData = try? JSONEncoder().encode(events) else { return nil }
        return String(data: jsonData, encoding: .utf8)
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
