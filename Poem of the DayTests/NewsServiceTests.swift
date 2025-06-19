//
//  NewsServiceTests.swift
//  Poem of the DayTests
//
//  Created by Claude Code on 2025-06-19.
//

import XCTest
@testable import Poem_of_the_Day

final class NewsServiceTests: XCTestCase {
    var sut: NewsService!
    var mockSession: MockURLSession!
    
    override func setUp() {
        mockSession = MockURLSession()
        sut = NewsService(session: mockSession)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
    }
    
    func testFetchDailyNews_WithValidRSS_ReturnsArticles() async throws {
        // Given
        let mockRSSData = createMockRSSData()
        mockSession.mockData = mockRSSData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let articles = try await sut.fetchDailyNews()
        
        // Then
        XCTAssertFalse(articles.isEmpty)
        XCTAssertLessThanOrEqual(articles.count, 20) // Should limit to 20 articles
        
        let firstArticle = articles.first!
        XCTAssertFalse(firstArticle.title.isEmpty)
        XCTAssertNotNil(firstArticle.publishedAt)
    }
    
    func testFetchDailyNews_WithNetworkError_ThrowsNetworkError() async {
        // Given
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        // When & Then
        do {
            _ = try await sut.fetchDailyNews()
            XCTFail("Expected error to be thrown")
        } catch let error as NewsError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \\(error)")
        }
    }
    
    func testFetchDailyNews_WithInvalidResponse_ThrowsError() async {
        // Given
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            _ = try await sut.fetchDailyNews()
            XCTFail("Expected error to be thrown")
        } catch let error as NewsError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error type: \\(error)")
        }
    }
    
    func testRSSParser_WithValidXML_ParsesCorrectly() throws {
        // Given
        let parser = RSSParser()
        let xmlData = createMockRSSData()
        
        // When
        let items = try parser.parse(data: xmlData)
        
        // Then
        XCTAssertFalse(items.isEmpty)
        
        let firstItem = items.first!
        XCTAssertEqual(firstItem.title, "Breaking: Scientists Discover New Species")
        XCTAssertEqual(firstItem.description, "Researchers have found a previously unknown species in the Amazon rainforest.")
        XCTAssertNotNil(firstItem.pubDate)
    }
    
    func testRSSParser_WithInvalidXML_ThrowsParsingError() {
        // Given
        let parser = RSSParser()
        let invalidXMLData = "Not valid XML".data(using: .utf8)!
        
        // When & Then
        XCTAssertThrowsError(try parser.parse(data: invalidXMLData)) { error in
            XCTAssertTrue(error is NewsError)
            XCTAssertEqual(error as? NewsError, .parsingFailed)
        }
    }
    
    func testNewsArticle_InitializesCorrectly() {
        // Given
        let title = "Test Title"
        let description = "Test Description"
        let content = "Test Content"
        let publishedAt = Date()
        let source = NewsSource(name: "Test Source", id: "test")
        let url = URL(string: "https://example.com")
        
        // When
        let article = NewsArticle(
            title: title,
            description: description,
            content: content,
            publishedAt: publishedAt,
            source: source,
            url: url
        )
        
        // Then
        XCTAssertEqual(article.title, title)
        XCTAssertEqual(article.description, description)
        XCTAssertEqual(article.content, content)
        XCTAssertEqual(article.publishedAt, publishedAt)
        XCTAssertEqual(article.source.name, source.name)
        XCTAssertEqual(article.url, url)
        XCTAssertNotNil(article.id)
    }
    
    func testNewsArticle_FullText_CombinesAllContent() {
        // Given
        let article = NewsArticle(
            title: "Title",
            description: "Description",
            content: "Content",
            publishedAt: Date(),
            source: NewsSource(name: "Source", id: "source"),
            url: nil
        )
        
        // When
        let fullText = article.fullText
        
        // Then
        XCTAssertEqual(fullText, "Title Description Content")
    }
    
    func testNewsAPIArticle_ToNewsArticle_ConvertsCorrectly() {
        // Given
        let apiArticle = NewsAPIArticle(
            source: NewsSource(name: "Test Source", id: "test"),
            title: "Test Title",
            description: "Test Description",
            content: "Test Content",
            publishedAt: "2025-06-19T12:00:00Z",
            url: "https://example.com"
        )
        
        // When
        let newsArticle = apiArticle.toNewsArticle()
        
        // Then
        XCTAssertNotNil(newsArticle)
        XCTAssertEqual(newsArticle?.title, "Test Title")
        XCTAssertEqual(newsArticle?.description, "Test Description")
        XCTAssertEqual(newsArticle?.content, "Test Content")
        XCTAssertNotNil(newsArticle?.publishedAt)
    }
    
    func testNewsAPIArticle_WithInvalidDate_ReturnsNil() {
        // Given
        let apiArticle = NewsAPIArticle(
            source: NewsSource(name: "Test Source", id: "test"),
            title: "Test Title",
            description: nil,
            content: nil,
            publishedAt: "invalid-date",
            url: nil
        )
        
        // When
        let newsArticle = apiArticle.toNewsArticle()
        
        // Then
        XCTAssertNil(newsArticle)
    }
    
    // MARK: - Helper Methods
    
    private func createMockRSSData() -> Data {
        let rssXML = \"\"\"\n        <?xml version=\"1.0\" encoding=\"UTF-8\"?>\n        <rss version=\"2.0\">\n            <channel>\n                <title>Test News Feed</title>\n                <description>A test RSS feed</description>\n                <item>\n                    <title>Breaking: Scientists Discover New Species</title>\n                    <description>Researchers have found a previously unknown species in the Amazon rainforest.</description>\n                    <link>https://example.com/article1</link>\n                    <pubDate>Wed, 19 Jun 2025 12:00:00 GMT</pubDate>\n                </item>\n                <item>\n                    <title>Technology Breakthrough in Renewable Energy</title>\n                    <description>New solar panel technology promises 50% efficiency improvement.</description>\n                    <link>https://example.com/article2</link>\n                    <pubDate>Wed, 19 Jun 2025 11:00:00 GMT</pubDate>\n                </item>\n            </channel>\n        </rss>\n        \"\"\"\n        \n        return rssXML.data(using: .utf8)!\n    }\n}\n\n// MARK: - Mock URL Session\n\nclass MockURLSession: URLSession {\n    var mockData: Data?\n    var mockResponse: URLResponse?\n    var mockError: Error?\n    \n    override func data(from url: URL) async throws -> (Data, URLResponse) {\n        if let error = mockError {\n            throw error\n        }\n        \n        let data = mockData ?? Data()\n        let response = mockResponse ?? HTTPURLResponse(\n            url: url,\n            statusCode: 200,\n            httpVersion: nil,\n            headerFields: nil\n        )!\n        \n        return (data, response)\n    }\n}