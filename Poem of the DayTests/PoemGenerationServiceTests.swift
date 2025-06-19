//
//  PoemGenerationServiceTests.swift
//  Poem of the DayTests
//
//  Created by Claude Code on 2025-06-19.
//

import XCTest
@testable import Poem_of_the_Day

final class PoemGenerationServiceTests: XCTestCase {
    var sut: MockPoemGenerationService!
    
    override func setUp() {
        sut = MockPoemGenerationService()
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testIsAvailable_WhenAvailable_ReturnsTrue() async {
        // Given
        sut.mockAvailable = true
        
        // When
        let isAvailable = await sut.isAvailable()
        
        // Then
        XCTAssertTrue(isAvailable)
    }
    
    func testIsAvailable_WhenNotAvailable_ReturnsFalse() async {
        // Given
        sut.mockAvailable = false
        
        // When
        let isAvailable = await sut.isAvailable()
        
        // Then
        XCTAssertFalse(isAvailable)
    }
    
    func testGeneratePoem_WithTheme_ReturnsCorrectPoem() async throws {
        // Given
        let theme = PoemTheme.nature
        
        // When
        let poem = try await sut.generatePoem(theme: theme)
        
        // Then
        XCTAssertEqual(poem.title, "Mock Nature Poem")
        XCTAssertTrue(poem.content.contains("nature"))
        XCTAssertEqual(poem.author, "Mock AI")
        XCTAssertEqual(poem.source, .api) // Mock uses default source
    }
    
    func testGeneratePoem_WithError_ThrowsError() async {
        // Given
        sut.mockError = PoemGenerationError.modelUnavailable
        
        // When & Then
        do {
            _ = try await sut.generatePoem(theme: .love)
            XCTFail("Expected error to be thrown")
        } catch let error as PoemGenerationError {
            XCTAssertEqual(error, .modelUnavailable)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testGenerateRandomPoem_ReturnsPoem() async throws {
        // When
        let poem = try await sut.generateRandomPoem()
        
        // Then
        XCTAssertNotNil(poem.title)
        XCTAssertFalse(poem.content.isEmpty)
        XCTAssertEqual(poem.author, "Mock AI")
    }
    
    func testPoemThemes_AllCasesHaveDisplayNames() {
        // When & Then
        for theme in PoemTheme.allCases {
            XCTAssertFalse(theme.displayName.isEmpty)
            XCTAssertFalse(theme.prompt.isEmpty)
        }
    }
    
    func testPoemGenerationError_LocalizedDescriptions() {
        let errors: [PoemGenerationError] = [
            .modelUnavailable,
            .generationFailed,
            .invalidPrompt,
            .deviceNotSupported,
            .contentFiltered,
            .quotaExceeded
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }
}

// MARK: - Real PoemGenerationService Tests (iOS 18.1+ only)

@available(iOS 18.1, *)
final class RealPoemGenerationServiceTests: XCTestCase {
    var sut: PoemGenerationService!
    
    override func setUp() {
        sut = PoemGenerationService()
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testIsAvailable_ChecksFoundationModelsAvailability() async {
        // This test will depend on the actual device capabilities
        // On simulator or devices without Neural Engine, it should return false
        let isAvailable = await sut.isAvailable()
        
        // We can't assert a specific value since it depends on the test environment
        // But we can ensure the method doesn't crash
        XCTAssertNotNil(isAvailable)
    }
    
    // Note: Actual AI generation tests would require a real device with iOS 18.1+
    // and would consume AI quota, so they should be integration tests rather than unit tests
}