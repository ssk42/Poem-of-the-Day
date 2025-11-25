import XCTest
@testable import Poem_of_the_Day

@MainActor
final class PoemViewModelTests: XCTestCase {
    
    var viewModel: PoemViewModel!
    var mockRepository: MockPoemRepository!
    var mockTelemetryService: MockTelemetryService!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPoemRepository()
        mockTelemetryService = MockTelemetryService()
        viewModel = PoemViewModel(
            repository: mockRepository,
            telemetryService: mockTelemetryService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockTelemetryService = nil
        super.tearDown()
    }
    
    func testInitialDataLoading() async {
        // Given
        let expectedPoem = TestData.samplePoem
        mockRepository.dailyPoem = expectedPoem
        mockRepository.isAIAvailable = true
        
        // When
        await viewModel.loadInitialData()
        
        // Then
        XCTAssertEqual(viewModel.poemOfTheDay?.title, expectedPoem.title)
        XCTAssertTrue(viewModel.isAIGenerationAvailable)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertGreaterThan(mockRepository.getDailyPoemCallCount, 0)
    }
    
    func testRefreshPoem() async {
        // Given
        let newPoem = TestData.vibePoem
        mockRepository.dailyPoem = newPoem
        
        // When
        await viewModel.refreshPoem()
        
        // Then
        XCTAssertEqual(viewModel.poemOfTheDay?.title, newPoem.title)
        XCTAssertEqual(mockRepository.refreshDailyPoemCallCount, 1)
    }
    
    func testToggleFavorite_AddToFavorites() async {
        // Given
        let poem = TestData.samplePoem
        mockRepository.favoritePoems = []
        
        // When
        await viewModel.toggleFavorite(poem: poem)
        
        // Then
        XCTAssertEqual(mockRepository.addToFavoritesCallCount, 1)
        XCTAssertEqual(mockRepository.removeFromFavoritesCallCount, 0)
    }
    
    func testToggleFavorite_RemoveFromFavorites() async {
        // Given
        let poem = TestData.samplePoem
        mockRepository.favoritePoems = [poem]
        
        // When
        await viewModel.toggleFavorite(poem: poem)
        
        // Then
        XCTAssertEqual(mockRepository.removeFromFavoritesCallCount, 1)
        XCTAssertEqual(mockRepository.addToFavoritesCallCount, 0)
    }
    
    func testGenerateVibeBasedPoem() async {
        // Given
        let vibePoem = TestData.vibePoem
        mockRepository.isAIAvailable = true
        
        // When
        await viewModel.generateVibeBasedPoem()
        
        // Then
        XCTAssertEqual(mockRepository.generateVibeBasedPoemCallCount, 1)
    }
    
    func testGenerateCustomPoem() async {
        // Given
        let customPrompt = "Write about friendship"
        mockRepository.isAIAvailable = true
        
        // When
        await viewModel.generateCustomPoem(prompt: customPrompt)
        
        // Then
        XCTAssertEqual(mockRepository.generateCustomPoemCallCount, 1)
    }
    
    func testErrorHandling() async {
        // Given
        mockRepository.shouldThrowError = true
        mockRepository.errorToThrow = .networkUnavailable
        
        // When
        await viewModel.refreshPoem()
        
        // Then
        XCTAssertTrue(viewModel.showErrorAlert)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.errorMessage!.isEmpty)
    }
    
    func testSharePoem() async {
        // Given
        let poem = TestData.samplePoem
        
        // When
        await viewModel.sharePoem(poem)
        
        // Then
        XCTAssertGreaterThan(mockTelemetryService.trackedEvents.count, 0)
    }
    
    func testIsFavorite() {
        // Given
        let poem = TestData.samplePoem
        viewModel.favorites = [poem]
        
        // When
        let isFavorite = viewModel.isFavorite(poem: poem)
        
        // Then
        XCTAssertTrue(isFavorite)
    }
    
    func testIsNotFavorite() {
        // Given
        let poem = TestData.samplePoem
        viewModel.favorites = []
        
        // When
        let isFavorite = viewModel.isFavorite(poem: poem)
        
        // Then
        XCTAssertFalse(isFavorite)
    }
} 