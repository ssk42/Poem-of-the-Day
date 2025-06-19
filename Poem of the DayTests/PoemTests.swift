import XCTest
@testable import Poem_of_the_Day

final class PoemTests: XCTestCase {
    func testPoemInitialization() {
        // Given
        let title = "Test Poem"
        let lines = ["Line 1", "Line 2", "Line 3"]
        let author = "Test Author"
        
        // When
        let poem = Poem(title: title, lines: lines, author: author)
        
        // Then
        XCTAssertEqual(poem.title, title)
        XCTAssertEqual(poem.content, lines.joined(separator: "\n"))
        XCTAssertEqual(poem.author, author)
        XCTAssertNotNil(poem.id)
    }
    
    func testPoemInitializationWithEmptyLines() {
        // Given
        let title = "Test Poem"
        let lines: [String] = []
        let author = "Test Author"
        
        // When
        let poem = Poem(title: title, lines: lines, author: author)
        
        // Then
        XCTAssertEqual(poem.title, title)
        XCTAssertEqual(poem.content, "")
        XCTAssertEqual(poem.author, author)
    }
    
    func testPoemInitializationWithNilAuthor() {
        // Given
        let title = "Test Poem"
        let lines = ["Line 1", "Line 2"]
        
        // When
        let poem = Poem(title: title, lines: lines)
        
        // Then
        XCTAssertEqual(poem.title, title)
        XCTAssertEqual(poem.content, lines.joined(separator: "\n"))
        XCTAssertNil(poem.author)
    }
    
    func testPoemShareText() {
        // Given
        let poem = Poem(title: "Test Poem", lines: ["Line 1", "Line 2"], author: "Test Author")
        
        // When
        let shareText = poem.shareText
        
        // Then
        let expectedText = "Test Poem\nby Test Author\n\nLine 1\nLine 2"
        XCTAssertEqual(shareText, expectedText)
    }
    
    func testPoemShareTextWithoutAuthor() {
        // Given
        let poem = Poem(title: "Test Poem", lines: ["Line 1", "Line 2"])
        
        // When
        let shareText = poem.shareText
        
        // Then
        let expectedText = "Test Poem\n\nLine 1\nLine 2"
        XCTAssertEqual(shareText, expectedText)
    }
    
    func testPoemEquality() {
        // Given
        let poem1 = Poem(title: "Test Poem", lines: ["Line 1"], author: "Test Author")
        let poem2 = Poem(title: "Test Poem", lines: ["Line 1"], author: "Test Author")
        let poem3 = Poem(title: "Different Poem", lines: ["Line 1"], author: "Test Author")
        
        // Then
        XCTAssertNotEqual(poem1, poem2) // Different IDs
        XCTAssertNotEqual(poem1, poem3) // Different content
    }
}

final class PoemViewModelTests: XCTestCase {
    var sut: PoemViewModel!
    var mockUserDefaults: UserDefaults!
    var mockURLSession: MockURLSession!
    
    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults(suiteName: "test.com.stevereitz.poemoftheday")
        mockURLSession = MockURLSession()
        sut = PoemViewModel()
        sut.sharedDefaults = mockUserDefaults
        sut.urlSession = mockURLSession
    }
    
    override func tearDown() {
        mockUserDefaults.removePersistentDomain(forName: "test.com.stevereitz.poemoftheday")
        sut = nil
        mockUserDefaults = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    func testToggleFavorite() {
        // Given
        let poem = Poem(title: "Test Poem", lines: ["Line 1"], author: "Test Author")
        
        // When
        sut.toggleFavorite(poem: poem)
        
        // Then
        XCTAssertTrue(sut.isFavorite(poem: poem))
        XCTAssertEqual(sut.favorites.count, 1)
        
        // When toggling again
        sut.toggleFavorite(poem: poem)
        
        // Then
        XCTAssertFalse(sut.isFavorite(poem: poem))
        XCTAssertEqual(sut.favorites.count, 0)
    }
    
    func testToggleFavoriteWithMultiplePoems() {
        // Given
        let poem1 = Poem(title: "Poem 1", lines: ["Line 1"], author: "Author 1")
        let poem2 = Poem(title: "Poem 2", lines: ["Line 2"], author: "Author 2")
        
        // When
        sut.toggleFavorite(poem: poem1)
        sut.toggleFavorite(poem: poem2)
        
        // Then
        XCTAssertTrue(sut.isFavorite(poem: poem1))
        XCTAssertTrue(sut.isFavorite(poem: poem2))
        XCTAssertEqual(sut.favorites.count, 2)
    }
    
    func testLoadFavorites() {
        // Given
        let poem = Poem(title: "Test Poem", lines: ["Line 1"], author: "Test Author")
        sut.favorites = [poem]
        sut.saveFavorites()
        
        // When
        sut.favorites = []
        sut.loadFavorites()
        
        // Then
        XCTAssertEqual(sut.favorites.count, 1)
        XCTAssertEqual(sut.favorites.first?.title, poem.title)
    }
    
    func testLoadFavoritesWithEmptyStorage() {
        // When
        sut.loadFavorites()
        
        // Then
        XCTAssertEqual(sut.favorites.count, 0)
    }
    
    func testLoadPoemFromSharedStorage() {
        // Given
        let title = "Test Poem"
        let content = "Line 1\nLine 2"
        let author = "Test Author"
        
        mockUserDefaults.set(title, forKey: "poemTitle")
        mockUserDefaults.set(content, forKey: "poemContent")
        mockUserDefaults.set(author, forKey: "poemAuthor")
        
        // When
        sut.loadPoemFromSharedStorage()
        
        // Then
        XCTAssertNotNil(sut.poemOfTheDay)
        XCTAssertEqual(sut.poemOfTheDay?.title, title)
        XCTAssertEqual(sut.poemOfTheDay?.content, content)
        XCTAssertEqual(sut.poemOfTheDay?.author, author)
    }
    
    func testLoadPoemFromSharedStorageWithMissingData() {
        // Given
        mockUserDefaults.set("Test Poem", forKey: "poemTitle")
        // Missing content and author
        
        // When
        sut.loadPoemFromSharedStorage()
        
        // Then
        XCTAssertNil(sut.poemOfTheDay)
    }
    
    func testFetchPoemOfTheDay() async {
        // Given
        let expectation = XCTestExpectation(description: "Fetch poem")
        let mockPoemData = """
        [{
            "title": "Test Poem",
            "lines": ["Line 1", "Line 2"],
            "author": "Test Author"
        }]
        """.data(using: .utf8)!
        
        mockURLSession.mockData = mockPoemData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        do {
            try await sut.fetchPoemOfTheDay()
            expectation.fulfill()
        } catch {
            XCTFail("Failed to fetch poem: \(error)")
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(sut.poemOfTheDay)
        XCTAssertEqual(sut.poemOfTheDay?.title, "Test Poem")
    }
    
    func testFetchPoemOfTheDayWithNetworkError() async {
        // Given
        let expectation = XCTestExpectation(description: "Fetch poem with error")
        mockURLSession.mockError = URLError(.notConnectedToInternet)
        
        // When
        do {
            try await sut.fetchPoemOfTheDay()
            XCTFail("Expected error but got success")
        } catch {
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNil(sut.poemOfTheDay)
    }
    
    func testFetchPoemOfTheDayWithInvalidData() async {
        // Given
        let expectation = XCTestExpectation(description: "Fetch poem with invalid data")
        mockURLSession.mockData = "Invalid JSON".data(using: .utf8)!
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        do {
            try await sut.fetchPoemOfTheDay()
            XCTFail("Expected error but got success")
        } catch {
            expectation.fulfill()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNil(sut.poemOfTheDay)
    }
    
    func testFetchPoemOfTheDayWithForce() async {
        // Given
        let expectation = XCTestExpectation(description: "Fetch poem with force")
        let mockPoemData = """
        [{
            "title": "Test Poem",
            "lines": ["Line 1", "Line 2"],
            "author": "Test Author"
        }]
        """.data(using: .utf8)!
        
        mockURLSession.mockData = mockPoemData
        mockURLSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        do {
            try await sut.fetchPoemOfTheDay(force: true)
            expectation.fulfill()
        } catch {
            XCTFail("Failed to fetch poem: \(error)")
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertNotNil(sut.poemOfTheDay)
    }
    
    func testCheckAndUpdateDailyPoem() {
        // Given
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        mockUserDefaults.set(yesterday, forKey: "lastPoemFetchDate")
        
        // When
        sut.checkAndUpdateDailyPoem()
        
        // Then
        // Verify that fetchPoemOfTheDay was called
        XCTAssertNotNil(mockURLSession.mockData)
    }
    
    func testCheckAndUpdateDailyPoemWithTodayDate() {
        // Given
        mockUserDefaults.set(Date(), forKey: "lastPoemFetchDate")
        
        // When
        sut.checkAndUpdateDailyPoem()
        
        // Then
        // Verify that fetchPoemOfTheDay was not called
        XCTAssertNil(mockURLSession.mockData)
    }
}

// MARK: - Mock URLSession for testing
class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return MockURLSessionDataTask {
            completionHandler(self.mockData, self.mockResponse, self.mockError)
        }
    }
}

class MockURLSessionDataTask: URLSessionDataTask {
    private let completionHandler: () -> Void
    
    init(completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler
    }
    
    override func resume() {
        completionHandler()
    }
} 