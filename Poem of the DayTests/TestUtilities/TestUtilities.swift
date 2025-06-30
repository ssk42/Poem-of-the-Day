import Foundation
import XCTest
@testable import Poem_of_the_Day

// MARK: - Test Utilities

final class TestUtilities {
    
    // MARK: - Test Environment Setup
    
    static func createTestDependencyContainer() -> DependencyContainer {
        let mockNetworkService = MockNetworkService()
        let mockNewsService = MockNewsService()
        let mockVibeAnalyzer = MockVibeAnalyzer()
        let mockAIService = MockPoemGenerationService()
        let mockTelemetryService = MockTelemetryService()
        let mockUserDefaults = TestData.createTestUserDefaults()
        
        let mockRepository = MockPoemRepository()
        
        return DependencyContainer(
            networkService: mockNetworkService,
            newsService: mockNewsService,
            vibeAnalyzer: mockVibeAnalyzer,
            aiService: mockAIService,
            telemetryService: mockTelemetryService,
            repository: mockRepository
        )
    }
    
    static func createIsolatedUserDefaults(suiteName: String = "test.suite") -> UserDefaults {
        let defaults = MockUserDefaults()
        return defaults
    }
    
    // MARK: - Async Testing Utilities
    
    static func waitForAsync<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withTimeout(timeout) {
            try await operation()
        }
    }
    
    static func withTimeout<T>(
        _ timeout: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Mock Configuration Helpers
    
    static func configureMockNetworkService(
        _ mock: MockNetworkService,
        scenario: TestData.TestScenario
    ) {
        mock.reset()
        
        switch scenario {
        case .normalOperation:
            mock.poemToReturn = TestData.samplePoem
        case .networkError:
            mock.shouldThrowError = true
            mock.errorToThrow = .networkUnavailable
        case .serverError:
            mock.shouldThrowError = true
            mock.errorToThrow = .serverError(500)
        case .rateLimited:
            mock.shouldThrowError = true
            mock.errorToThrow = .rateLimited
        case .slowResponse:
            mock.delayDuration = 3.0
        case .emptyData:
            mock.shouldThrowError = true
            mock.errorToThrow = .noPoems
        default:
            break
        }
    }
    
    static func configureMockNewsService(
        _ mock: MockNewsService,
        scenario: TestData.TestScenario
    ) {
        mock.reset()
        
        switch scenario {
        case .normalOperation:
            mock.articlesToReturn = TestData.sampleNewsArticles
        case .networkError:
            mock.shouldThrowError = true
            mock.errorToThrow = .networkUnavailable
        case .emptyData:
            mock.articlesToReturn = []
        default:
            break
        }
    }
    
    static func configureMockAIService(
        _ mock: MockPoemGenerationService,
        scenario: TestData.TestScenario
    ) {
        mock.reset()
        
        switch scenario {
        case .normalOperation:
            mock.isServiceAvailable = true
        case .aiUnavailable:
            mock.isServiceAvailable = false
        case .aiError:
            mock.isServiceAvailable = true
            mock.shouldThrowError = true
            mock.errorToThrow = .generationFailed
        default:
            break
        }
    }
    
    // MARK: - Data Verification Helpers
    
    static func verifyPoem(
        _ poem: Poem,
        hasTitle title: String? = nil,
        hasAuthor author: String? = nil,
        hasLineCount lineCount: Int? = nil,
        hasVibe vibe: DailyVibe? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if let expectedTitle = title {
            XCTAssertEqual(poem.title, expectedTitle, "Poem title mismatch", file: file, line: line)
        }
        
        if let expectedAuthor = author {
            XCTAssertEqual(poem.author, expectedAuthor, "Poem author mismatch", file: file, line: line)
        }
        
        if let expectedLineCount = lineCount {
            XCTAssertEqual(poem.lines.count, expectedLineCount, "Poem line count mismatch", file: file, line: line)
        }
        
        if let expectedVibe = vibe {
            XCTAssertEqual(poem.vibe, expectedVibe, "Poem vibe mismatch", file: file, line: line)
        }
        
        // Basic validation
        XCTAssertFalse(poem.title.isEmpty, "Poem title should not be empty", file: file, line: line)
        XCTAssertFalse(poem.author.isEmpty, "Poem author should not be empty", file: file, line: line)
        XCTAssertFalse(poem.lines.isEmpty, "Poem should have lines", file: file, line: line)
    }
    
    static func verifyVibeAnalysis(
        _ analysis: VibeAnalysis,
        hasVibe vibe: DailyVibe? = nil,
        minimumConfidence: Double? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if let expectedVibe = vibe {
            XCTAssertEqual(analysis.vibe, expectedVibe, "Vibe analysis mismatch", file: file, line: line)
        }
        
        if let minConfidence = minimumConfidence {
            XCTAssertGreaterThanOrEqual(analysis.confidence, minConfidence, "Confidence too low", file: file, line: line)
        }
        
        // Basic validation
        XCTAssertGreaterThanOrEqual(analysis.confidence, 0.0, "Confidence should be non-negative", file: file, line: line)
        XCTAssertLessThanOrEqual(analysis.confidence, 1.0, "Confidence should not exceed 1.0", file: file, line: line)
        XCTAssertFalse(analysis.reasoning.isEmpty, "Analysis should have reasoning", file: file, line: line)
        XCTAssertFalse(analysis.keywords.isEmpty, "Analysis should have keywords", file: file, line: line)
    }
    
    static func verifyTelemetryEvent<T: TelemetryEvent>(
        _ event: T,
        hasEventName eventName: String? = nil,
        hasSource source: TelemetrySource? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        if let expectedEventName = eventName {
            XCTAssertEqual(event.eventName, expectedEventName, "Event name mismatch", file: file, line: line)
        }
        
        if let expectedSource = source {
            XCTAssertEqual(event.source, expectedSource, "Event source mismatch", file: file, line: line)
        }
        
        // Basic validation
        XCTAssertFalse(event.eventName.isEmpty, "Event name should not be empty", file: file, line: line)
    }
    
    // MARK: - Performance Testing Helpers
    
    static func measurePerformance<T>(
        name: String = "Operation",
        operation: () async throws -> T
    ) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        print("⏱️ \(name) completed in \(String(format: "%.3f", duration))s")
        return (result, duration)
    }
    
    static func verifyPerformance(
        _ duration: TimeInterval,
        isLessThan maxDuration: TimeInterval,
        operation: String = "Operation",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertLessThan(
            duration,
            maxDuration,
            "\(operation) took \(String(format: "%.3f", duration))s, expected < \(String(format: "%.3f", maxDuration))s",
            file: file,
            line: line
        )
    }
    
    // MARK: - UI Testing Helpers
    
    static func findElement(
        in app: XCUIApplication,
        withIdentifier identifier: String,
        timeout: TimeInterval = 5.0
    ) -> XCUIElement? {
        let element = app.otherElements[identifier]
        return element.waitForExistence(timeout: timeout) ? element : nil
    }
    
    static func findButton(
        in app: XCUIApplication,
        withText text: String,
        timeout: TimeInterval = 5.0
    ) -> XCUIElement? {
        let button = app.buttons[text]
        return button.waitForExistence(timeout: timeout) ? button : nil
    }
    
    static func waitForElementToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0
    ) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }
    
    // MARK: - Test Data Cleanup
    
    static func cleanupTestData() {
        // Clean up any test files or persistent data
        let testUserDefaults = UserDefaults(suiteName: "test.suite")
        testUserDefaults?.removePersistentDomain(forName: "test.suite")
        
        // Clear any temporary test files
        let tempDirectory = FileManager.default.temporaryDirectory
        let testFiles = try? FileManager.default.contentsOfDirectory(
            at: tempDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("test_") }
        
        testFiles?.forEach { url in
            try? FileManager.default.removeItem(at: url)
        }
    }
}

// MARK: - Test Error Types

enum TestError: Error, LocalizedError {
    case timeout
    case setupFailed
    case verificationFailed(String)
    case unexpectedValue(expected: Any, actual: Any)
    
    var errorDescription: String? {
        switch self {
        case .timeout:
            return "Test operation timed out"
        case .setupFailed:
            return "Test setup failed"
        case .verificationFailed(let message):
            return "Verification failed: \(message)"
        case .unexpectedValue(let expected, let actual):
            return "Expected \(expected), but got \(actual)"
        }
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    func waitForAsyncOperation<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        return try await TestUtilities.waitForAsync(timeout: timeout, operation: operation)
    }
    
    func verifyAsync<T>(
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T,
        verification: @escaping (T) throws -> Void
    ) async throws {
        let result = try await waitForAsyncOperation(timeout: timeout, operation: operation)
        try verification(result)
    }
    
    func expectationForAsyncOperation<T>(
        description: String,
        timeout: TimeInterval = 5.0,
        operation: @escaping () async throws -> T
    ) -> XCTestExpectation {
        let expectation = expectation(description: description)
        
        Task {
            do {
                _ = try await operation()
                expectation.fulfill()
            } catch {
                XCTFail("Async operation failed: \(error)")
                expectation.fulfill()
            }
        }
        
        return expectation
    }
}

// MARK: - Accessibility Testing Helpers

extension TestUtilities {
    
    static func verifyAccessibilityLabels(
        in app: XCUIApplication,
        expectedLabels: [String],
        file: StaticString = #file,
        line: UInt = #line
    ) {
        for label in expectedLabels {
            let element = app.otherElements[label].firstMatch
            XCTAssertTrue(
                element.exists,
                "Element with accessibility label '\(label)' should exist",
                file: file,
                line: line
            )
        }
    }
    
    static func verifyVoiceOverSupport(
        for element: XCUIElement,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(element.isAccessibilityElement, "Element should be accessible to VoiceOver", file: file, line: line)
        XCTAssertFalse(element.label.isEmpty, "Element should have accessibility label", file: file, line: line)
    }
}