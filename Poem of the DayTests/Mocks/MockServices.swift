import Foundation
import XCTest
@testable import Poem_of_the_Day

// MARK: - Mock Network Service

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: PoemError = .networkUnavailable
    var delayDuration: TimeInterval = 0
    var poemToReturn: Poem?
    var callCount = 0
    
    func fetchRandomPoem() async throws -> Poem {
        callCount += 1
        
        if delayDuration > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let poem = poemToReturn {
            return poem
        }
        
        return TestData.samplePoem
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = .networkUnavailable
        delayDuration = 0
        poemToReturn = nil
        callCount = 0
    }
}

// MARK: - Mock News Service

final class MockNewsService: NewsServiceProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: NewsError = .networkUnavailable
    var articlesToReturn: [NewsArticle] = []
    var callCount = 0
    
    func fetchDailyNews() async throws -> [NewsArticle] {
        callCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !articlesToReturn.isEmpty {
            return articlesToReturn
        }
        
        return TestData.sampleNewsArticles
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = .networkUnavailable
        articlesToReturn = []
        callCount = 0
    }
}

// MARK: - Mock Vibe Analyzer

final class MockVibeAnalyzer: VibeAnalyzerProtocol, @unchecked Sendable {
    var vibeToReturn: VibeAnalysis?
    var callCount = 0
    
    func analyzeVibe(from articles: [NewsArticle]) async -> VibeAnalysis {
        callCount += 1
        
        if let vibe = vibeToReturn {
            return vibe
        }
        
        return TestData.sampleVibeAnalysis
    }
    
    func reset() {
        vibeToReturn = nil
        callCount = 0
    }
}

// MARK: - Mock AI Service

final class MockPoemGenerationService: PoemGenerationServiceProtocol, @unchecked Sendable {
    var isServiceAvailable = true
    var shouldThrowError = false
    var errorToThrow: PoemGenerationError = .unsupportedDevice
    var poemToReturn: Poem?
    var generationCallCount = 0
    var customPromptCallCount = 0
    var availabilityCallCount = 0
    
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem {
        generationCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let poem = poemToReturn {
            return poem
        }
        
        return TestData.sampleAIPoem(vibe: vibeAnalysis.vibe)
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        customPromptCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let poem = poemToReturn {
            return poem
        }
        
        return TestData.sampleCustomPoem(prompt: prompt)
    }
    
    func isAvailable() async -> Bool {
        availabilityCallCount += 1
        return isServiceAvailable
    }
    
    func reset() {
        isServiceAvailable = true
        shouldThrowError = false
        errorToThrow = .unsupportedDevice
        poemToReturn = nil
        generationCallCount = 0
        customPromptCallCount = 0
        availabilityCallCount = 0
    }
}

// MARK: - Mock Poem Repository

final class MockPoemRepository: PoemRepositoryProtocol, @unchecked Sendable {
    var dailyPoem: Poem?
    var favoritePoems: [Poem] = []
    var vibeAnalysis: VibeAnalysis?
    var isAIAvailable = false
    var shouldThrowError = false
    var errorToThrow: PoemError = .networkUnavailable
    
    // Call tracking
    var getDailyPoemCallCount = 0
    var refreshDailyPoemCallCount = 0
    var generateVibeBasedPoemCallCount = 0
    var generateCustomPoemCallCount = 0
    var getVibeOfTheDayCallCount = 0
    var isAIGenerationAvailableCallCount = 0
    var getFavoritesCallCount = 0
    var addToFavoritesCallCount = 0
    var removeFromFavoritesCallCount = 0
    var isFavoriteCallCount = 0
    
    func getDailyPoem() async throws -> Poem {
        getDailyPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let poem = dailyPoem {
            return poem
        }
        
        return TestData.samplePoem
    }
    
    func refreshDailyPoem() async throws -> Poem {
        refreshDailyPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        let newPoem = TestData.samplePoem
        dailyPoem = newPoem
        return newPoem
    }
    
    func generateVibeBasedPoem() async throws -> Poem {
        generateVibeBasedPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !isAIAvailable {
            throw PoemError.unsupportedOperation
        }
        
        return TestData.sampleAIPoem(vibe: .hopeful)
    }
    
    func generateCustomPoem(prompt: String) async throws -> Poem {
        generateCustomPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if !isAIAvailable {
            throw PoemError.unsupportedOperation
        }
        
        return TestData.sampleCustomPoem(prompt: prompt)
    }
    
    func getVibeOfTheDay() async throws -> VibeAnalysis {
        getVibeOfTheDayCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if let vibe = vibeAnalysis {
            return vibe
        }
        
        return TestData.sampleVibeAnalysis
    }
    
    func isAIGenerationAvailable() async -> Bool {
        isAIGenerationAvailableCallCount += 1
        return isAIAvailable
    }
    
    func getFavorites() async -> [Poem] {
        getFavoritesCallCount += 1
        return favoritePoems
    }
    
    func addToFavorites(_ poem: Poem) async {
        addToFavoritesCallCount += 1
        if !favoritePoems.contains(where: { $0.id == poem.id }) {
            favoritePoems.append(poem)
        }
    }
    
    func removeFromFavorites(_ poem: Poem) async {
        removeFromFavoritesCallCount += 1
        favoritePoems.removeAll { $0.id == poem.id }
    }
    
    func isFavorite(_ poem: Poem) async -> Bool {
        isFavoriteCallCount += 1
        return favoritePoems.contains { $0.id == poem.id }
    }
    
    func reset() {
        dailyPoem = nil
        favoritePoems = []
        vibeAnalysis = nil
        isAIAvailable = false
        shouldThrowError = false
        errorToThrow = .networkUnavailable
        
        // Reset call counts
        getDailyPoemCallCount = 0
        refreshDailyPoemCallCount = 0
        generateVibeBasedPoemCallCount = 0
        generateCustomPoemCallCount = 0
        getVibeOfTheDayCallCount = 0
        isAIGenerationAvailableCallCount = 0
        getFavoritesCallCount = 0
        addToFavoritesCallCount = 0
        removeFromFavoritesCallCount = 0
        isFavoriteCallCount = 0
    }
}

// MARK: - Mock Telemetry Service

final class MockTelemetryService: TelemetryServiceProtocol, @unchecked Sendable {
    private var trackedEvents: [TelemetryEvent] = []
    private var _isEnabled = true
    private var _configuration = TelemetryConfiguration.default
    
    func track(_ event: TelemetryEvent) async {
        trackedEvents.append(event)
    }
    
    func flush() async {
        // Mock implementation - events are kept in memory
    }
    
    func configure(with configuration: TelemetryConfiguration) async {
        _configuration = configuration
        _isEnabled = configuration.isEnabled
    }
    
    func isEnabled() async -> Bool {
        return _isEnabled
    }
    
    func getEventCount() async -> Int {
        return trackedEvents.count
    }
    
    func exportAllEvents() async -> [AnyTelemetryEvent] {
        return trackedEvents.map { AnyTelemetryEvent($0) }
    }
    
    func exportEventsAsJSON() async -> String? {
        let events = trackedEvents.map { AnyTelemetryEvent($0) }
        guard let jsonData = try? JSONEncoder().encode(events) else { return nil }
        return String(data: jsonData, encoding: .utf8)
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
    
    func getEventsByName(_ eventName: String) -> [TelemetryEvent] {
        return trackedEvents.filter { $0.eventName == eventName }
    }
    
    func reset() {
        trackedEvents.removeAll()
        _isEnabled = true
        _configuration = .default
    }
}

// MARK: - Mock Error Types

enum MockError: Error, LocalizedError, CaseIterable {
    case networkTimeout
    case invalidData
    case serverError
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .networkTimeout:
            return "Network request timed out"
        case .invalidData:
            return "Invalid data received"
        case .serverError:
            return "Server error occurred"
        case .rateLimited:
            return "Rate limit exceeded"
        }
    }
}

// MARK: - Mock UserDefaults

final class MockUserDefaults: UserDefaults {
    private var storage: [String: Any] = [:]
    
    override func object(forKey defaultName: String) -> Any? {
        return storage[defaultName]
    }
    
    override func set(_ value: Any?, forKey defaultName: String) {
        storage[defaultName] = value
    }
    
    override func removeObject(forKey defaultName: String) {
        storage.removeValue(forKey: defaultName)
    }
    
    override func array(forKey defaultName: String) -> [Any]? {
        return storage[defaultName] as? [Any]
    }
    
    override func bool(forKey defaultName: String) -> Bool {
        return storage[defaultName] as? Bool ?? false
    }
    
    override func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    override func data(forKey defaultName: String) -> Data? {
        return storage[defaultName] as? Data
    }
    
    func clear() {
        storage.removeAll()
    }
}