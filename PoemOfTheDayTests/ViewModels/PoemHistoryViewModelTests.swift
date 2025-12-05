import XCTest
@testable import Poem_of_the_Day

@MainActor
final class PoemHistoryViewModelTests: XCTestCase {
    
    var viewModel: PoemHistoryViewModel!
    var mockRepository: MockPoemRepository!
    var mockHistoryService: MockHistoryService!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockPoemRepository()
        mockHistoryService = MockHistoryService()
        viewModel = PoemHistoryViewModel(
            repository: mockRepository,
            historyService: mockHistoryService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockRepository = nil
        mockHistoryService = nil
        super.tearDown()
    }
    
    // MARK: - Load History Tests
    
    func testLoadPoemHistory_SetsEntries() async {
        // Given
        let entry = PoemHistoryEntry(poem: TestData.samplePoem, source: .api, vibeAtTime: nil)
        mockRepository.mockHistory = [entry]
        
        // When
        await viewModel.loadPoemHistory()
        
        // Then
        XCTAssertEqual(viewModel.historyEntries.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadHistory_SetsGroupedHistoryAndStreak() async {
        // Given
        await mockHistoryService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        
        // When
        await viewModel.loadHistory()
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNotNil(viewModel.streakInfo)
    }
    
    // MARK: - Clear History Tests
    
    func testClearHistory_ClearsGroupedHistory() async {
        // Given
        await mockHistoryService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        await viewModel.loadHistory()
        
        // When
        await viewModel.clearHistory()
        
        // Then
        XCTAssertTrue(viewModel.groupedHistory.isEmpty)
        XCTAssertEqual(viewModel.streakInfo?.currentStreak, 0)
        XCTAssertEqual(viewModel.streakInfo?.longestStreak, 0)
    }
    
    // MARK: - Delete Entry Tests
    
    func testDeleteEntry_ReloadsHistory() async {
        // Given
        await mockHistoryService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        await viewModel.loadHistory()
        let historyEntries = await mockHistoryService.getHistory()
        
        guard let entryToDelete = historyEntries.first else {
            XCTFail("Expected history entry")
            return
        }
        
        // When
        await viewModel.deleteEntry(entryToDelete)
        
        // Then
        let updatedHistory = await mockHistoryService.getHistory()
        XCTAssertEqual(updatedHistory.count, 0)
    }
    
    // MARK: - Get Poem Tests
    
    func testGetPoemForDate_ReturnsCorrectPoem() async {
        // Given
        let entry = PoemHistoryEntry(poem: TestData.samplePoem, source: .api, vibeAtTime: nil)
        mockRepository.mockHistory = [entry]
        
        // When
        let poem = await viewModel.getPoemForDate(Date())
        
        // Then
        XCTAssertNotNil(poem)
        XCTAssertEqual(poem?.id, TestData.samplePoem.id)
    }
    
    func testGetPoemForDate_ReturnsNilForNoMatch() async {
        // Given
        mockRepository.mockHistory = []
        
        // When
        let poem = await viewModel.getPoemForDate(Date())
        
        // Then
        XCTAssertNil(poem)
    }
    
    func testGetPoemsForDateRange_FiltersCorrectly() async {
        // Given
        let today = Date()
        let entry = PoemHistoryEntry(poem: TestData.samplePoem, viewedDate: today, source: .api, vibeAtTime: nil)
        mockRepository.mockHistory = [entry]
        
        // When
        let startDate = today.addingTimeInterval(-86400) // Yesterday
        let endDate = today.addingTimeInterval(86400) // Tomorrow
        let poems = await viewModel.getPoemsForDateRange(start: startDate, end: endDate)
        
        // Then
        XCTAssertEqual(poems.count, 1)
    }
    
    // MARK: - Validation Tests
    
    func testIsValidHistoryDate_RejectsFuture() {
        // Given
        let futureDate = Date().addingTimeInterval(86400) // Tomorrow
        let pastDate = Date().addingTimeInterval(-86400) // Yesterday
        
        // When/Then
        XCTAssertFalse(viewModel.isValidHistoryDate(futureDate))
        XCTAssertTrue(viewModel.isValidHistoryDate(pastDate))
        XCTAssertTrue(viewModel.isValidHistoryDate(Date()))
    }
    
    // MARK: - Format Tests
    
    func testFormatDateForDisplay_FormatsCorrectly() {
        // Given
        let date = Date()
        
        // When
        let formatted = viewModel.formatDateForDisplay(date)
        
        // Then
        XCTAssertFalse(formatted.isEmpty)
    }
    
    // MARK: - State Tests
    
    func testSetLoadingState_UpdatesIsLoading() {
        // When
        viewModel.setLoadingState(true)
        
        // Then
        XCTAssertTrue(viewModel.isLoading)
        
        // When
        viewModel.setLoadingState(false)
        
        // Then
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSetError_SetsErrorMessageAndShowsAlert() {
        // Given
        let errorMessage = "Test error"
        
        // When
        viewModel.setError(errorMessage)
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, errorMessage)
        XCTAssertTrue(viewModel.showErrorAlert)
    }
}
