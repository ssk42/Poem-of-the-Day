import XCTest
@testable import Poem_of_the_Day

final class NetworkServiceTests: XCTestCase {
    
    var mockNetworkService: MockNetworkService!
    
    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
    }
    
    override func tearDown() {
        mockNetworkService = nil
        super.tearDown()
    }
    
    func testFetchRandomPoem_Success() async throws {
        // Given
        let expectedPoem = TestData.samplePoem
        mockNetworkService.poemToReturn = expectedPoem
        
        // When
        let result = try await mockNetworkService.fetchRandomPoem()
        
        // Then
        XCTAssertEqual(result.title, expectedPoem.title)
        XCTAssertEqual(result.author, expectedPoem.author)
        XCTAssertEqual(mockNetworkService.callCount, 1)
    }
    
    func testFetchRandomPoem_NetworkError() async {
        // Given
        mockNetworkService.shouldThrowError = true
        mockNetworkService.errorToThrow = .networkUnavailable
        
        // When/Then
        do {
            _ = try await mockNetworkService.fetchRandomPoem()
            XCTFail("Expected network error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_ServerError() async {
        // Given
        mockNetworkService.shouldThrowError = true
        mockNetworkService.errorToThrow = .serverError(500)
        
        // When/Then
        do {
            _ = try await mockNetworkService.fetchRandomPoem()
            XCTFail("Expected server error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .serverError(500))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_RateLimited() async {
        // Given
        mockNetworkService.shouldThrowError = true
        mockNetworkService.errorToThrow = .rateLimited
        
        // When/Then
        do {
            _ = try await mockNetworkService.fetchRandomPoem()
            XCTFail("Expected rate limit error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .rateLimited)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_NoPoems() async {
        // Given
        mockNetworkService.shouldThrowError = true
        mockNetworkService.errorToThrow = .noPoems
        
        // When/Then
        do {
            _ = try await mockNetworkService.fetchRandomPoem()
            XCTFail("Expected no poems error")
        } catch let error as PoemError {
            XCTAssertEqual(error, .noPoems)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testFetchRandomPoem_WithDelay() async throws {
        // Given
        let expectedPoem = TestData.samplePoem
        mockNetworkService.poemToReturn = expectedPoem
        mockNetworkService.delayDuration = 0.1
        
        let startTime = Date()
        
        // When
        let result = try await mockNetworkService.fetchRandomPoem()
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        
        // Then
        XCTAssertEqual(result.title, expectedPoem.title)
        XCTAssertGreaterThanOrEqual(elapsedTime, 0.1)
    }
} 