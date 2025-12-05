import XCTest
@testable import Poem_of_the_Day

final class PoemErrorTests: XCTestCase {
    
    // MARK: - Error Description Tests
    
    func testErrorDescriptions_AllCasesHaveDescriptions() {
        let errors: [PoemError] = [
            .networkUnavailable,
            .invalidResponse,
            .decodingFailed,
            .noPoems,
            .rateLimited,
            .serverError(500),
            .unsupportedOperation,
            .localGenerationFailed,
            .unknownError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "\(error) should have an error description")
            XCTAssertFalse(error.errorDescription!.isEmpty, "\(error) error description should not be empty")
        }
    }
    
    func testErrorDescriptions_SpecificMessages() {
        XCTAssertTrue(PoemError.networkUnavailable.errorDescription!.contains("Network"))
        XCTAssertTrue(PoemError.invalidResponse.errorDescription!.contains("invalid response"))
        XCTAssertTrue(PoemError.decodingFailed.errorDescription!.contains("process"))
        XCTAssertTrue(PoemError.noPoems.errorDescription!.contains("No poems"))
        XCTAssertTrue(PoemError.rateLimited.errorDescription!.contains("Too many"))
        XCTAssertTrue(PoemError.serverError(503).errorDescription!.contains("503"))
        XCTAssertTrue(PoemError.unsupportedOperation.errorDescription!.contains("not available"))
        XCTAssertTrue(PoemError.localGenerationFailed.errorDescription!.contains("generate"))
        XCTAssertTrue(PoemError.unknownError.errorDescription!.contains("unexpected"))
    }
    
    // MARK: - Recovery Suggestion Tests
    
    func testRecoverySuggestions_AllCasesHaveSuggestions() {
        let errors: [PoemError] = [
            .networkUnavailable,
            .invalidResponse,
            .decodingFailed,
            .noPoems,
            .rateLimited,
            .serverError(500),
            .unsupportedOperation,
            .localGenerationFailed,
            .unknownError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.recoverySuggestion, "\(error) should have a recovery suggestion")
            XCTAssertFalse(error.recoverySuggestion!.isEmpty, "\(error) recovery suggestion should not be empty")
        }
    }
    
    func testRecoverySuggestions_SpecificMessages() {
        XCTAssertTrue(PoemError.networkUnavailable.recoverySuggestion!.contains("internet"))
        XCTAssertTrue(PoemError.rateLimited.recoverySuggestion!.contains("Wait"))
        XCTAssertTrue(PoemError.unsupportedOperation.recoverySuggestion!.contains("iOS 18.1"))
    }
    
    // MARK: - Equality Tests
    
    func testEquality_SameErrors() {
        XCTAssertEqual(PoemError.networkUnavailable, PoemError.networkUnavailable)
        XCTAssertEqual(PoemError.invalidResponse, PoemError.invalidResponse)
        XCTAssertEqual(PoemError.decodingFailed, PoemError.decodingFailed)
        XCTAssertEqual(PoemError.noPoems, PoemError.noPoems)
        XCTAssertEqual(PoemError.rateLimited, PoemError.rateLimited)
        XCTAssertEqual(PoemError.unsupportedOperation, PoemError.unsupportedOperation)
        XCTAssertEqual(PoemError.localGenerationFailed, PoemError.localGenerationFailed)
        XCTAssertEqual(PoemError.unknownError, PoemError.unknownError)
    }
    
    func testEquality_DifferentErrors() {
        XCTAssertNotEqual(PoemError.networkUnavailable, PoemError.invalidResponse)
        XCTAssertNotEqual(PoemError.rateLimited, PoemError.noPoems)
        XCTAssertNotEqual(PoemError.serverError(500), PoemError.serverError(503))
    }
    
    func testEquality_ServerErrorWithDifferentCodes() {
        XCTAssertEqual(PoemError.serverError(500), PoemError.serverError(500))
        XCTAssertEqual(PoemError.serverError(503), PoemError.serverError(503))
        XCTAssertNotEqual(PoemError.serverError(500), PoemError.serverError(503))
    }
    
    // MARK: - Server Error Code Tests
    
    func testServerError_IncludesStatusCode() {
        let error500 = PoemError.serverError(500)
        let error503 = PoemError.serverError(503)
        let error502 = PoemError.serverError(502)
        
        XCTAssertTrue(error500.errorDescription!.contains("500"))
        XCTAssertTrue(error503.errorDescription!.contains("503"))
        XCTAssertTrue(error502.errorDescription!.contains("502"))
    }
    
    // MARK: - LocalizedError Conformance Tests
    
    func testLocalizedError_Conformance() {
        let error: LocalizedError = PoemError.networkUnavailable
        
        XCTAssertNotNil(error.errorDescription)
        XCTAssertNotNil(error.recoverySuggestion)
    }
}
