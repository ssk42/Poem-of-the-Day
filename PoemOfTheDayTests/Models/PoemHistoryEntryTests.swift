import XCTest
@testable import Poem_of_the_Day

final class PoemHistoryEntryTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitialization_SetsAllProperties() {
        // Given
        let poem = TestData.samplePoem
        let viewedDate = Date()
        let source: PoemSource = .api
        let vibe: DailyVibe = .hopeful
        
        // When
        let entry = PoemHistoryEntry(
            poem: poem,
            viewedDate: viewedDate,
            source: source,
            vibeAtTime: vibe
        )
        
        // Then
        XCTAssertEqual(entry.poem.id, poem.id)
        XCTAssertEqual(entry.source, source)
        XCTAssertEqual(entry.vibeAtTime, vibe)
        XCTAssertNotNil(entry.id)
    }
    
    func testInitialization_UsesDefaultValues() {
        // Given
        let poem = TestData.samplePoem
        
        // When
        let entry = PoemHistoryEntry(poem: poem)
        
        // Then
        XCTAssertEqual(entry.source, .api)
        XCTAssertNil(entry.vibeAtTime)
    }
    
    func testInitialization_InheritsVibeFromPoem() {
        // Given
        let poem = TestData.vibePoem // This poem has a vibe
        
        // When
        let entry = PoemHistoryEntry(poem: poem, source: .aiGenerated)
        
        // Then
        XCTAssertEqual(entry.vibeAtTime, poem.vibe)
    }
    
    // MARK: - Date Formatting Tests
    
    func testFormattedDate_ReturnsCorrectFormat() {
        // Given
        let poem = TestData.samplePoem
        let entry = PoemHistoryEntry(poem: poem)
        
        // When
        let formatted = entry.formattedDate
        
        // Then
        XCTAssertFalse(formatted.isEmpty)
        // Should contain month, day, and year in some form
    }
    
    func testDayOfWeek_ReturnsCorrectDay() {
        // Given
        let poem = TestData.samplePoem
        let entry = PoemHistoryEntry(poem: poem)
        
        // When
        let dayOfWeek = entry.dayOfWeek
        
        // Then
        XCTAssertFalse(dayOfWeek.isEmpty)
        let validDays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        XCTAssertTrue(validDays.contains(dayOfWeek), "Day of week should be a valid day name")
    }
    
    // MARK: - Relative Date Tests
    
    func testIsToday_ReturnsTrueForToday() {
        // Given
        let poem = TestData.samplePoem
        let entry = PoemHistoryEntry(poem: poem, viewedDate: Date())
        
        // When/Then
        XCTAssertTrue(entry.isToday)
        XCTAssertFalse(entry.isYesterday)
    }
    
    func testIsYesterday_ReturnsTrueForYesterday() {
        // Given
        let poem = TestData.samplePoem
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let entry = PoemHistoryEntry(poem: poem, viewedDate: yesterday)
        
        // When/Then
        XCTAssertFalse(entry.isToday)
        XCTAssertTrue(entry.isYesterday)
    }
    
    func testRelativeDateString_ReturnsToday() {
        // Given
        let poem = TestData.samplePoem
        let entry = PoemHistoryEntry(poem: poem, viewedDate: Date())
        
        // When
        let relativeString = entry.relativeDateString
        
        // Then
        XCTAssertEqual(relativeString, "Today")
    }
    
    func testRelativeDateString_ReturnsYesterday() {
        // Given
        let poem = TestData.samplePoem
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let entry = PoemHistoryEntry(poem: poem, viewedDate: yesterday)
        
        // When
        let relativeString = entry.relativeDateString
        
        // Then
        XCTAssertEqual(relativeString, "Yesterday")
    }
    
    func testRelativeDateString_ReturnsFormattedDate() {
        // Given
        let poem = TestData.samplePoem
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let entry = PoemHistoryEntry(poem: poem, viewedDate: twoDaysAgo)
        
        // When
        let relativeString = entry.relativeDateString
        
        // Then
        XCTAssertNotEqual(relativeString, "Today")
        XCTAssertNotEqual(relativeString, "Yesterday")
        XCTAssertEqual(relativeString, entry.formattedDate)
    }
    
    // MARK: - Codable Tests
    
    func testCodable_EncodesAndDecodes() throws {
        // Given
        let poem = TestData.samplePoem
        let entry = PoemHistoryEntry(poem: poem, source: .aiGenerated, vibeAtTime: .hopeful)
        
        // When
        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(PoemHistoryEntry.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.id, entry.id)
        XCTAssertEqual(decoded.poem.id, entry.poem.id)
        XCTAssertEqual(decoded.source, entry.source)
        XCTAssertEqual(decoded.vibeAtTime, entry.vibeAtTime)
    }
    
    // MARK: - PoemSource Tests
    
    func testPoemSource_DisplayName() {
        XCTAssertEqual(PoemSource.api.displayName, "PoetryDB")
        XCTAssertEqual(PoemSource.aiGenerated.displayName, "AI Generated")
        XCTAssertEqual(PoemSource.customPrompt.displayName, "Custom")
        XCTAssertEqual(PoemSource.cached.displayName, "Cached")
    }
    
    func testPoemSource_Icon() {
        XCTAssertEqual(PoemSource.api.icon, "network")
        XCTAssertEqual(PoemSource.aiGenerated.icon, "brain.head.profile")
        XCTAssertEqual(PoemSource.customPrompt.icon, "pencil.and.outline")
        XCTAssertEqual(PoemSource.cached.icon, "internaldrive")
    }
    
    // MARK: - StreakInfo Tests
    
    func testStreakInfo_Empty() {
        let empty = StreakInfo.empty
        
        XCTAssertEqual(empty.currentStreak, 0)
        XCTAssertEqual(empty.longestStreak, 0)
        XCTAssertEqual(empty.totalDaysWithPoems, 0)
        XCTAssertNil(empty.lastViewedDate)
    }
    
    func testStreakInfo_Codable() throws {
        // Given
        let streakInfo = StreakInfo(
            currentStreak: 5,
            longestStreak: 10,
            totalDaysWithPoems: 50,
            lastViewedDate: Date()
        )
        
        // When
        let encoded = try JSONEncoder().encode(streakInfo)
        let decoded = try JSONDecoder().decode(StreakInfo.self, from: encoded)
        
        // Then
        XCTAssertEqual(decoded.currentStreak, streakInfo.currentStreak)
        XCTAssertEqual(decoded.longestStreak, streakInfo.longestStreak)
        XCTAssertEqual(decoded.totalDaysWithPoems, streakInfo.totalDaysWithPoems)
    }
}
