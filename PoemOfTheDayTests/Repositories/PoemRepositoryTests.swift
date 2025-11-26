import XCTest
@testable import Poem_of_the_Day


class MockWidgetReloader: WidgetReloaderProtocol {
    var reloadAllTimelinesCallCount = 0
    
    func reloadAllTimelines() {
        reloadAllTimelinesCallCount += 1
    }
}
final class PoemRepositoryTests: XCTestCase {
    
    var repository: PoemRepository!
    var mockNetworkService: MockNetworkService!
    var mockNewsService: MockNewsService!
    var mockVibeAnalyzer: MockVibeAnalyzer!
    var mockTelemetryService: MockTelemetryService!
    var mockAIService: MockPoemGenerationService!
    var mockWidgetReloader: MockWidgetReloader!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        mockNewsService = MockNewsService()
        mockVibeAnalyzer = MockVibeAnalyzer()
        mockTelemetryService = MockTelemetryService()
        mockAIService = MockPoemGenerationService()
        mockWidgetReloader = MockWidgetReloader()
        
        // Reset all mocks to clean state
        mockNetworkService.reset()
        mockNewsService.reset()
        mockVibeAnalyzer.reset()
        mockTelemetryService.reset()
        mockAIService.reset()
        
        repository = PoemRepository(
            networkService: mockNetworkService,
            newsService: mockNewsService,
            vibeAnalyzer: mockVibeAnalyzer,
            aiService: mockAIService,
            telemetryService: mockTelemetryService,
            userDefaults: TestData.createTestUserDefaults(),
            widgetReloader: mockWidgetReloader
        )
    }
    
    override func tearDown() {
        // Reset all mocks
        mockNetworkService?.reset()
        mockNewsService?.reset() 
        mockVibeAnalyzer?.reset()
        mockTelemetryService?.reset()
        mockAIService?.reset()
        
        repository = nil
        mockNetworkService = nil
        mockNewsService = nil
        mockVibeAnalyzer = nil
        mockTelemetryService = nil
        mockAIService = nil
        mockWidgetReloader = nil
        super.tearDown()
    }
    
    func testGetDailyPoem_Success() async throws {
        // Given
        let expectedPoem = TestData.samplePoem
        mockNetworkService.poemToReturn = expectedPoem
        
        // Create a repository without AI service to test network fallback
        repository = PoemRepository(
            networkService: mockNetworkService,
            newsService: mockNewsService,
            vibeAnalyzer: mockVibeAnalyzer,
            aiService: nil,
            telemetryService: mockTelemetryService,
            userDefaults: TestData.createTestUserDefaults(),
            widgetReloader: mockWidgetReloader
        )
        
        // When
        let result = try await repository.getDailyPoem()
        
        // Then
        XCTAssertEqual(result.title, expectedPoem.title)
        XCTAssertEqual(result.author, expectedPoem.author)
        XCTAssertEqual(mockNetworkService.callCount, 1)
    }
    
    func testGetDailyPoem_NetworkError() async {
        // Given
        mockNetworkService.shouldThrowError = true
        mockNetworkService.errorToThrow = .networkUnavailable
        
        // Create a repository without AI service to test network fallback
        repository = PoemRepository(
            networkService: mockNetworkService,
            newsService: mockNewsService,
            vibeAnalyzer: mockVibeAnalyzer,
            aiService: nil,
            telemetryService: mockTelemetryService,
            userDefaults: TestData.createTestUserDefaults(),
            widgetReloader: mockWidgetReloader
        )
        
        // When/Then
        do {
            _ = try await repository.getDailyPoem()
            XCTFail("Expected network error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testRefreshDailyPoem() async throws {
        // Given
        let newPoem = TestData.vibePoem
        mockNetworkService.poemToReturn = newPoem
        
        // When
        let result = try await repository.refreshDailyPoem()
        
        // Then
        XCTAssertEqual(result.title, newPoem.title)
        XCTAssertEqual(mockNetworkService.callCount, 1)
    }
    
    func testGenerateVibeBasedPoem() async throws {
        // Given
        let expectedNews = TestData.sampleNewsArticles
        let expectedAnalysis = TestData.sampleVibeAnalysis
        let expectedPoem = TestData.vibePoem
        
        mockNewsService.newsToReturn = expectedNews
        mockVibeAnalyzer.analysisToReturn = expectedAnalysis
        mockAIService.poemToReturn = expectedPoem
        mockAIService.isAvailableValue = true
        
        // When
        let result = try await repository.generateVibeBasedPoem()
        
        // Then
        XCTAssertEqual(result.title, expectedPoem.title)
        XCTAssertEqual(result.vibe, expectedAnalysis.vibe)
        XCTAssertEqual(mockNewsService.callCount, 1)
        XCTAssertEqual(mockVibeAnalyzer.callCount, 1)
        XCTAssertEqual(mockAIService.generateFromVibeCallCount, 1)
        XCTAssertEqual(mockWidgetReloader.reloadAllTimelinesCallCount, 1)
    }
    
    func testGenerateCustomPoem() async throws {
        // Given
        let prompt = "Write about friendship"
        let expectedPoem = TestData.customPoem
        mockAIService.poemToReturn = expectedPoem
        mockAIService.isAvailableValue = true
        
        // When
        let result = try await repository.generateCustomPoem(prompt: prompt)
        
        // Then
        XCTAssertEqual(result.title, expectedPoem.title)
        XCTAssertEqual(mockAIService.generateWithPromptCallCount, 1)
    }
    
    func testAddToFavorites() async {
        // Given
        let poem = TestData.samplePoem
        
        // When
        await repository.addToFavorites(poem)
        let favorites = await repository.getFavorites()
        
        // Then
        XCTAssertTrue(favorites.contains { $0.id == poem.id })
    }
    
    func testRemoveFromFavorites() async {
        // Given
        let poem = TestData.samplePoem
        await repository.addToFavorites(poem)
        
        // When
        await repository.removeFromFavorites(poem)
        let favorites = await repository.getFavorites()
        
        // Then
        XCTAssertFalse(favorites.contains { $0.id == poem.id })
    }
    
    func testGetFavoritePoems() async {
        // Given
        let poem1 = TestData.samplePoem
        let poem2 = TestData.vibePoem
        
        // Reset telemetry service first
        // Note: MockTelemetryService will start fresh for each test
        
        await repository.addToFavorites(poem1)
        await repository.addToFavorites(poem2)
        
        // When
        let favorites = await repository.getFavorites()
        
        // Then
        XCTAssertEqual(favorites.count, 2)
        XCTAssertTrue(favorites.contains { $0.id == poem1.id })
        XCTAssertTrue(favorites.contains { $0.id == poem2.id })
    }
    
    func testCheckAIAvailability() async {
        // Given
        mockAIService.isAvailableValue = true
        
        // When
        let isAvailable = await repository.isAIGenerationAvailable()
        
        // Then
        XCTAssertTrue(isAvailable)
        XCTAssertEqual(mockAIService.isAvailableCallCount, 1)
    }
    
    func testTelemetryTracking() async throws {
        // Given
        let expectedPoem = TestData.samplePoem
        mockNetworkService.poemToReturn = expectedPoem
        
        // Create a repository without AI service to test network fallback
        repository = PoemRepository(
            networkService: mockNetworkService,
            newsService: mockNewsService,
            vibeAnalyzer: mockVibeAnalyzer,
            aiService: nil,
            telemetryService: mockTelemetryService,
            userDefaults: TestData.createTestUserDefaults(),
            widgetReloader: mockWidgetReloader
        )
        
        // When
        _ = try await repository.getDailyPoem()
        
        // Then
        XCTAssertGreaterThan(mockTelemetryService.trackedEvents.count, 0)
    }
} 