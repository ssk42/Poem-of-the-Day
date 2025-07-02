import XCTest
@testable import Poem_of_the_Day

final class NewsServiceTests: XCTestCase {
    
    var mockNewsService: MockNewsService!
    
    override func setUp() {
        super.setUp()
        mockNewsService = MockNewsService()
    }
    
    override func tearDown() {
        mockNewsService = nil
        super.tearDown()
    }
    
    func testFetchDailyNews_Success() async throws {
        // Given
        let expectedNews = TestData.sampleNewsArticles
        mockNewsService.newsToReturn = expectedNews
        
        // When
        let result = try await mockNewsService.fetchDailyNews()
        
        // Then
        XCTAssertEqual(result.count, expectedNews.count)
        XCTAssertEqual(result.first?.title, expectedNews.first?.title)
        XCTAssertEqual(mockNewsService.callCount, 1)
    }
    
    func testFetchDailyNews_NetworkError() async {
        // Given
        mockNewsService.shouldThrowError = true
        mockNewsService.errorToThrow = .networkUnavailable
        
        // When/Then
        do {
            _ = try await mockNewsService.fetchDailyNews()
            XCTFail("Expected network error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchDailyNews_ServerError() async {
        // Given
        mockNewsService.shouldThrowError = true
        mockNewsService.errorToThrow = .serverError(500)
        
        // When/Then
        do {
            _ = try await mockNewsService.fetchDailyNews()
            XCTFail("Expected server error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .serverError(500))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchDailyNews_RateLimited() async {
        // Given
        mockNewsService.shouldThrowError = true
        mockNewsService.errorToThrow = .rateLimited
        
        // When/Then
        do {
            _ = try await mockNewsService.fetchDailyNews()
            XCTFail("Expected rate limit error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .rateLimited)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchDailyNews_NoArticles() async {
        // Given
        mockNewsService.shouldThrowError = true
        mockNewsService.errorToThrow = .noPoems
        
        // When/Then
        do {
            _ = try await mockNewsService.fetchDailyNews()
            XCTFail("Expected no articles error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .noPoems)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchDailyNews_WithDelay() async throws {
        // Given
        let expectedNews = TestData.sampleNewsArticles
        mockNewsService.newsToReturn = expectedNews
        mockNewsService.delayDuration = 0.1
        
        let startTime = Date()
        
        // When
        let result = try await mockNewsService.fetchDailyNews()
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(result.count, expectedNews.count)
        XCTAssertGreaterThanOrEqual(elapsedTime, 0.1)
    }
    
    func testFetchDailyNews_EmptyResult() async throws {
        // Given
        mockNewsService.newsToReturn = []
        
        // When
        let result = try await mockNewsService.fetchDailyNews()
        
        // Then
        XCTAssertTrue(result.isEmpty)
        XCTAssertEqual(mockNewsService.callCount, 1)
    }
    
    func testNewsArticleProperties() {
        // Given
        let article = TestData.sampleNewsArticles.first!
        
        // When/Then
        XCTAssertFalse(article.title.isEmpty)
        XCTAssertFalse(article.fullText.isEmpty)
        XCTAssertNotNil(article.url)
        XCTAssertNotNil(article.publishedAt)
        XCTAssertFalse(article.source.name.isEmpty)
    }
    
    func testNewsSourceProperties() {
        // Given
        let newsSource = TestData.sampleNewsArticles.first!.source
        
        // When/Then
        XCTAssertFalse(newsSource.name.isEmpty)
        XCTAssertFalse(newsSource.id?.isEmpty ?? true)
    }
} 