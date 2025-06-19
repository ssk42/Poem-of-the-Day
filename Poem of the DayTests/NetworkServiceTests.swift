//
//  NetworkServiceTests.swift
//  Poem of the DayTests
//
//  Created by Claude Code on 2025-06-19.
//

import XCTest
@testable import Poem_of_the_Day

final class NetworkServiceTests: XCTestCase {
    var sut: NetworkService!
    var mockSession: MockURLSession!
    
    override func setUp() async throws {
        mockSession = MockURLSession()
        sut = NetworkService(session: mockSession)
    }
    
    override func tearDown() {
        sut = nil
        mockSession = nil
    }
    
    func testFetchRandomPoem_Success() async throws {
        // Given
        let mockPoemData = """
        [{
            "title": "Test Poem",
            "lines": ["Line 1", "Line 2"],
            "author": "Test Author"
        }]
        """.data(using: .utf8)!
        
        mockSession.mockData = mockPoemData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When
        let poem = try await sut.fetchRandomPoem()
        
        // Then
        XCTAssertEqual(poem.title, "Test Poem")
        XCTAssertEqual(poem.content, "Line 1\nLine 2")
        XCTAssertEqual(poem.author, "Test Author")
    }
    
    func testFetchRandomPoem_NetworkError() async {
        // Given
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        // When & Then
        do {
            _ = try await sut.fetchRandomPoem()
            XCTFail("Expected error to be thrown")
        } catch let error as PoemError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_404Error() async {
        // Given
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = Data()
        
        // When & Then
        do {
            _ = try await sut.fetchRandomPoem()
            XCTFail("Expected error to be thrown")
        } catch let error as PoemError {
            XCTAssertEqual(error, .noPoems)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_InvalidJSON() async {
        // Given
        mockSession.mockData = "Invalid JSON".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            _ = try await sut.fetchRandomPoem()
            XCTFail("Expected error to be thrown")
        } catch let error as PoemError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_EmptyResponse() async {
        // Given
        let mockPoemData = "[]".data(using: .utf8)!
        
        mockSession.mockData = mockPoemData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // When & Then
        do {
            _ = try await sut.fetchRandomPoem()
            XCTFail("Expected error to be thrown")
        } catch let error as PoemError {
            XCTAssertEqual(error, .noPoems)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_RateLimited() async {
        // Given
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://poetrydb.org/random")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        mockSession.mockData = Data()
        
        // When & Then
        do {
            _ = try await sut.fetchRandomPoem()
            XCTFail("Expected error to be thrown")
        } catch let error as PoemError {
            XCTAssertEqual(error, .rateLimited)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Mock URLSession

final class MockURLSession: URLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    
    override func data(from url: URL) async throws -> (Data, URLResponse) {
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw URLError(.unknown)
        }
        
        return (data, response)
    }
}