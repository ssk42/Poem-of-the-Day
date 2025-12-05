import XCTest
@testable import Poem_of_the_Day

final class PoemHistoryServiceTests: XCTestCase {
    
    var historyService: PoemHistoryService!
    var testUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        testUserDefaults = UserDefaults(suiteName: "test.history.\(UUID().uuidString)")!
        historyService = PoemHistoryService(userDefaults: testUserDefaults)
    }
    
    override func tearDown() {
        testUserDefaults.removePersistentDomain(forName: testUserDefaults.description)
        testUserDefaults = nil
        historyService = nil
        super.tearDown()
    }
    
    // MARK: - Add Entry Tests
    
    func testAddEntry_Success() async {
        // Given
        let poem = TestData.samplePoem
        
        // When
        await historyService.addEntry(poem, source: .api, vibe: .hopeful)
        let history = await historyService.getHistory()
        
        // Then
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.poem.id, poem.id)
        XCTAssertEqual(history.first?.source, .api)
        XCTAssertEqual(history.first?.vibeAtTime, .hopeful)
    }
    
    func testAddEntry_PreventsDuplicateSameDay() async {
        // Given
        let poem = TestData.samplePoem
        
        // When - Add same poem twice on same day
        await historyService.addEntry(poem, source: .api, vibe: nil)
        await historyService.addEntry(poem, source: .api, vibe: nil)
        let history = await historyService.getHistory()
        
        // Then - Should only have one entry
        XCTAssertEqual(history.count, 1)
    }
    
    func testAddEntry_AllowsDifferentPoemsSameDay() async {
        // Given
        let poem1 = TestData.samplePoem
        let poem2 = TestData.vibePoem
        
        // When
        await historyService.addEntry(poem1, source: .api, vibe: nil)
        await historyService.addEntry(poem2, source: .aiGenerated, vibe: .hopeful)
        let history = await historyService.getHistory()
        
        // Then
        XCTAssertEqual(history.count, 2)
    }
    
    // MARK: - Get History Tests
    
    func testGetHistory_ReturnsEntriesInOrder() async {
        // Given
        let poem1 = TestData.samplePoem
        let poem2 = TestData.vibePoem
        
        // When
        await historyService.addEntry(poem1, source: .api, vibe: nil)
        await historyService.addEntry(poem2, source: .aiGenerated, vibe: .hopeful)
        let history = await historyService.getHistory()
        
        // Then - Most recent first
        XCTAssertEqual(history.first?.poem.id, poem2.id)
    }
    
    func testGetHistoryForDate_FiltersCorrectly() async {
        // Given
        let poem = TestData.samplePoem
        await historyService.addEntry(poem, source: .api, vibe: nil)
        
        // When
        let todayHistory = await historyService.getHistory(for: Date())
        let yesterdayHistory = await historyService.getHistory(for: Date().addingTimeInterval(-86400))
        
        // Then
        XCTAssertEqual(todayHistory.count, 1)
        XCTAssertEqual(yesterdayHistory.count, 0)
    }
    
    func testGetHistoryGroupedByDate_GroupsCorrectly() async {
        // Given
        let poem = TestData.samplePoem
        await historyService.addEntry(poem, source: .api, vibe: nil)
        
        // When
        let grouped = await historyService.getHistoryGroupedByDate()
        
        // Then
        XCTAssertEqual(grouped.count, 1)
        XCTAssertEqual(grouped.first?.entries.count, 1)
    }
    
    // MARK: - Clear and Delete Tests
    
    func testClearHistory_RemovesAllEntries() async {
        // Given
        await historyService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        await historyService.addEntry(TestData.vibePoem, source: .aiGenerated, vibe: .hopeful)
        
        // When
        await historyService.clearHistory()
        let history = await historyService.getHistory()
        
        // Then
        XCTAssertTrue(history.isEmpty)
    }
    
    func testDeleteEntry_RemovesSpecificEntry() async {
        // Given
        let poem1 = TestData.samplePoem
        let poem2 = TestData.vibePoem
        await historyService.addEntry(poem1, source: .api, vibe: nil)
        await historyService.addEntry(poem2, source: .aiGenerated, vibe: .hopeful)
        let history = await historyService.getHistory()
        let entryToDelete = history.first!
        
        // When
        await historyService.deleteEntry(entryToDelete)
        let updatedHistory = await historyService.getHistory()
        
        // Then
        XCTAssertEqual(updatedHistory.count, 1)
        XCTAssertNotEqual(updatedHistory.first?.id, entryToDelete.id)
    }
    
    // MARK: - Count Tests
    
    func testGetEntryCount_ReturnsCorrectCount() async {
        // Given
        await historyService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        await historyService.addEntry(TestData.vibePoem, source: .aiGenerated, vibe: .hopeful)
        
        // When
        let count = await historyService.getEntryCount()
        
        // Then
        XCTAssertEqual(count, 2)
    }
    
    func testGetUniquePoems_CountsUniquePoemIds() async {
        // Given
        await historyService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        await historyService.addEntry(TestData.vibePoem, source: .aiGenerated, vibe: .hopeful)
        
        // When
        let uniqueCount = await historyService.getUniquePoems()
        
        // Then
        XCTAssertEqual(uniqueCount, 2)
    }
    
    // MARK: - Streak Tests
    
    func testGetStreakInfo_EmptyHistory() async {
        // When
        let streakInfo = await historyService.getStreakInfo()
        
        // Then
        XCTAssertEqual(streakInfo.currentStreak, 0)
        XCTAssertEqual(streakInfo.longestStreak, 0)
        XCTAssertEqual(streakInfo.totalDaysWithPoems, 0)
        XCTAssertNil(streakInfo.lastViewedDate)
    }
    
    func testGetStreakInfo_SingleDayStreak() async {
        // Given
        await historyService.addEntry(TestData.samplePoem, source: .api, vibe: nil)
        
        // When
        let streakInfo = await historyService.getStreakInfo()
        
        // Then
        XCTAssertEqual(streakInfo.currentStreak, 1)
        XCTAssertEqual(streakInfo.longestStreak, 1)
        XCTAssertEqual(streakInfo.totalDaysWithPoems, 1)
        XCTAssertNotNil(streakInfo.lastViewedDate)
    }
}
