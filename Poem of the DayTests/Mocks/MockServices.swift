import Foundation
import XCTest
@testable import Poem_of_the_Day

// MARK: - Mock Network Service

final class MockNetworkService: NetworkServiceProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: PoemError = .networkUnavailable
    var poemToReturn: Poem?
    var delayDuration: TimeInterval = 0
    var callCount = 0
    
    func fetchRandomPoem() async throws -> Poem {
        callCount += 1
        
        if delayDuration > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let poem = poemToReturn else {
            throw PoemError.noPoems
        }
        
        return poem
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = .networkUnavailable
        poemToReturn = nil
        delayDuration = 0
        callCount = 0
    }
}

// MARK: - Mock News Service

final class MockNewsService: NewsServiceProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: PoemError = .networkUnavailable  // Using PoemError since NewsError doesn't exist
    var newsToReturn: [NewsArticle] = []
    var delayDuration: TimeInterval = 0
    var callCount = 0
    
    func fetchDailyNews() async throws -> [NewsArticle] {
        callCount += 1
        
        if delayDuration > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return newsToReturn
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = .networkUnavailable
        newsToReturn = []
        delayDuration = 0
        callCount = 0
    }
}

// MARK: - Mock Vibe Analyzer

final class MockVibeAnalyzer: VibeAnalyzerProtocol, @unchecked Sendable {
    var analysisToReturn: VibeAnalysis?
    var callCount = 0
    
    func analyzeVibe(from articles: [NewsArticle]) async -> VibeAnalysis {
        callCount += 1
        
        if let analysis = analysisToReturn {
            return analysis
        }
        
        return VibeAnalysis(
            vibe: .contemplative,
            confidence: 0.7,
            reasoning: "Mock analysis",
            keywords: ["test", "mock"],
            sentiment: SentimentScore(positivity: 0.5, energy: 0.5, complexity: 0.5)
        )
    }
    
    func reset() {
        analysisToReturn = nil
        callCount = 0
    }
}

// MARK: - Mock AI Service

final class MockPoemGenerationService: PoemGenerationServiceProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: Error = PoemGenerationError.generationFailed  // Using PoemGenerationError from new service
    var delayDuration: TimeInterval = 0
    var poemToReturn: Poem?
    var isAvailableValue = true
    var generateFromVibeCallCount = 0
    var generateWithPromptCallCount = 0
    var isAvailableCallCount = 0
    
    func generatePoemFromVibe(_ vibeAnalysis: VibeAnalysis) async throws -> Poem {
        generateFromVibeCallCount += 1
        
        if delayDuration > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return poemToReturn ?? TestData.vibePoem
    }
    
    func generatePoemWithCustomPrompt(_ prompt: String) async throws -> Poem {
        generateWithPromptCallCount += 1
        
        if delayDuration > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return poemToReturn ?? TestData.customPoem
    }
    
    func isAvailable() async -> Bool {
        isAvailableCallCount += 1
        return isAvailableValue
    }
    
    func reset() {
        shouldThrowError = false
        errorToThrow = PoemGenerationError.generationFailed
        delayDuration = 0
        poemToReturn = nil
        isAvailableValue = true
        generateFromVibeCallCount = 0
        generateWithPromptCallCount = 0
        isAvailableCallCount = 0
    }
}

// MARK: - Mock Poem Repository

final class MockPoemRepository: PoemRepositoryProtocol, @unchecked Sendable {
    var shouldThrowError = false
    var errorToThrow: PoemError = .networkUnavailable
    var dailyPoem: Poem?
    var favoritePoems: [Poem] = []
    var vibeAnalysis: VibeAnalysis?
    var isAIAvailable = false
    var delayDuration: TimeInterval = 0
    
    // Call counters
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
    var getHistoryCallCount = 0
    var getHistoryGroupedByDateCallCount = 0
    var getStreakInfoCallCount = 0
    
    var mockHistory: [PoemHistoryEntry] = []
    var mockStreakInfo: StreakInfo = .empty
    
    func getDailyPoem() async throws -> Poem {
        getDailyPoemCallCount += 1
        
        if delayDuration > 0 {
            try await Task.sleep(nanoseconds: UInt64(delayDuration * 1_000_000_000))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return dailyPoem ?? TestData.samplePoem
    }
    
    func refreshDailyPoem() async throws -> Poem {
        refreshDailyPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return dailyPoem ?? TestData.samplePoem
    }
    
    func generateVibeBasedPoem() async throws -> Poem {
        generateVibeBasedPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return TestData.vibePoem
    }
    
    func generateCustomPoem(prompt: String) async throws -> Poem {
        generateCustomPoemCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return TestData.customPoem
    }
    
    func getVibeOfTheDay() async throws -> VibeAnalysis {
        getVibeOfTheDayCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return vibeAnalysis ?? TestData.sampleVibeAnalysis
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
        favoritePoems.append(poem)
    }
    
    func removeFromFavorites(_ poem: Poem) async {
        removeFromFavoritesCallCount += 1
        favoritePoems.removeAll { $0.id == poem.id }
    }
    
    func isFavorite(_ poem: Poem) async -> Bool {
        isFavoriteCallCount += 1
        return favoritePoems.contains { $0.id == poem.id }
    }
    
    func getHistory() async -> [PoemHistoryEntry] {
        getHistoryCallCount += 1
        return mockHistory
    }
    
    func getHistoryGroupedByDate() async -> [(date: Date, entries: [PoemHistoryEntry])] {
        getHistoryGroupedByDateCallCount += 1
        let grouped = Dictionary(grouping: mockHistory) { entry in
            Calendar.current.startOfDay(for: entry.viewedDate)
        }
        return grouped.map { (date: $0.key, entries: $0.value) }
            .sorted { $0.date > $1.date }
    }
    
    func getStreakInfo() async -> StreakInfo {
        getStreakInfoCallCount += 1
        return mockStreakInfo
    }
    
    func reset() {
        dailyPoem = nil
        favoritePoems = []
        vibeAnalysis = nil
        isAIAvailable = false
        shouldThrowError = false
        errorToThrow = .networkUnavailable
        
        // Reset call counters
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
        getHistoryCallCount = 0
        getHistoryGroupedByDateCallCount = 0
        getStreakInfoCallCount = 0
        mockHistory = []
        mockStreakInfo = .empty
        delayDuration = 0
    }
}

// MARK: - Mock Telemetry Service

final class MockTelemetryService: TelemetryServiceProtocol, @unchecked Sendable {
    private(set) var trackedEvents: [TelemetryEvent] = []
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
        let events = trackedEvents.map { AnyTelemetryEvent($0) }
        guard let jsonData = try? JSONEncoder().encode(events) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    func reset() {
        trackedEvents.removeAll()
        _isEnabled = true
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